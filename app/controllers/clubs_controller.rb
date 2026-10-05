class ClubsController < ApplicationController
  before_action :set_member_club, only: :show
  before_action :authorize_club_overview!, only: :show
  before_action :set_owned_club, only: %i[edit update]

  def index
    @clubs = Club.joins(:club_memberships)
                 .where(club_memberships: { user_id: current_user.id, role: %i[owner admin] })
                       .includes(:club_memberships, tournaments: %i[tournament_registrations clock_state blind_levels charge_options])
                       .then { |clubs| filter_clubs(clubs) }
    @tournaments_by_club = @clubs.index_with { |club| club_featured_tournament(club) }
    @can_create_club = current_user.can_create_club?
  end

  def show
    live_first = "CASE WHEN tournaments.status = 'posted' AND " \
                 "tournament_clock_states.status IN ('running', 'paused', 'overtime') " \
                 "THEN 0 ELSE 1 END"
    @tournaments = @club.tournaments.with_attached_cover
                         .includes(:charge_options)
                         .left_joins(:clock_state)
                         .order(Arel.sql(live_first), starts_at: :asc)
    @confirmed_registrations_by_tournament = confirmed_registrations_by_tournament
    @active_players_count = @club.club_memberships.where(role: :player).count
  end

  def new
    return redirect_to clubs_path, alert: "Você já possui o limite de #{User::MAX_OWNED_CLUBS} clubes." unless current_user.can_create_club?

    @club = Club.new
  end

  def create
    @club = Club.new(club_params)

    case create_club_with_owner_membership
    when :created
      redirect_after_club_creation
    when :limit_reached
      redirect_to clubs_path, alert: "Você já possui o limite de #{User::MAX_OWNED_CLUBS} clubes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @club.update(club_params)
      redirect_to clubs_path, notice: "Clube atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_member_club
    @club = current_user.clubs.find(params[:id])
    @current_membership = @club.club_memberships.find_by!(user: current_user)
  end

  def authorize_club_overview!
    return if @current_membership.owner? ||
              @current_membership.admin? ||
              @current_membership.dealer?

    render plain: "Forbidden", status: :forbidden
  end

  def set_owned_club
    @club = current_user.owned_clubs.find(params[:id])
  end

  def club_params
    params.require(:club).permit(
      :name,
      :whatsapp_contact_number,
      :pix_key,
      :pix_key_type,
      :pix_recipient_name
    )
  end

  def create_club_with_owner_membership
    current_user.with_lock do
      return :limit_reached unless current_user.can_create_club?

      ActiveRecord::Base.transaction do
        @club.save!
        @club.club_memberships.create!(
          user: current_user,
          role: :owner
        )
      end
    end

    :created
  rescue ActiveRecord::RecordInvalid
    :invalid
  end

  def redirect_after_club_creation
    plan_id = active_plan_id_for_redirect

    if plan_id
      redirect_to new_club_subscription_path(plan_id: plan_id),
                  notice: "Clube criado com sucesso. Agora escolha o clube para contratar o plano."
    else
      redirect_to clubs_path, notice: "Clube criado com sucesso."
    end
  end

  def active_plan_id_for_redirect
    plan_id = params[:plan_id]
    return if plan_id.blank?

    Plan.active.exists?(id: plan_id) ? plan_id : nil
  end

  def confirmed_registrations_by_tournament
    TournamentRegistration.confirmed
                          .where(tournament_id: @tournaments.select(:id))
                          .group(:tournament_id)
                          .count
  end

  def filter_clubs(clubs)
    return clubs if params[:query].blank?

    query = "%#{Club.sanitize_sql_like(params[:query].strip)}%"
    clubs.where("clubs.name ILIKE ?", query)
  end

  def club_featured_tournament(club)
    live = club.tournaments.select { |tournament| tournament.clock_state&.running? || tournament.clock_state&.paused? || tournament.clock_state&.overtime? }
    return live.max_by(&:starts_at) if live.any?

    club.tournaments.select { |tournament| tournament.posted? && tournament.starts_at >= Time.current }
        .max_by(&:starts_at)
  end

end
