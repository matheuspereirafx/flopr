class ClubsController < ApplicationController
  before_action :set_member_club, only: :show
  before_action :authorize_club_overview!, only: :show
  before_action :set_owned_club, only: %i[edit update destroy]

  def index
    @clubs = current_user.clubs
                       .includes(:club_memberships, tournaments: %i[tournament_registrations clock_state blind_levels charge_options])
                       .then { |clubs| filter_clubs(clubs) }
    @tournaments_by_club = @clubs.index_with { |club| club_featured_tournament(club) }
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
    @club = Club.new
  end

  def create
    @club = Club.new(club_params)

    if create_club_with_owner_membership
      redirect_to clubs_path, notice: "Clube criado com sucesso."
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

  def destroy
    @club.destroy

    redirect_to clubs_path,
                notice: "Clube excluído com sucesso.",
                status: :see_other
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
    ActiveRecord::Base.transaction do
      @club.save!
      # Esta criando o membership com id do club, id user e passando ja um role .
      @club.club_memberships.create!(
        user: current_user,
        role: :owner
      )
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
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
