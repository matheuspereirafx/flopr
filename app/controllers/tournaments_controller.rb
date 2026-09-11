class TournamentsController < ApplicationController
  before_action :set_member_club
  before_action :authorize_owner!, only: %i[new create edit update destroy]
  before_action :set_tournament, only: %i[show edit update destroy finish join]
  before_action :authorize_tournament_deletion!, only: :destroy
  before_action :authorize_tournament_finishing!, only: :finish
  before_action :authorize_tournament_join!, only: :join

  def index
    @tournaments = @club.tournaments.with_attached_cover.order(starts_at: :asc)
    @confirmed_registrations_by_tournament = TournamentRegistration.confirmed
                                                               .where(tournament_id: @tournaments.select(:id))
                                                               .group(:tournament_id)
                                                               .count
  end
  def new
    @tournament = @club.tournaments.build

    Tournament::MINIMUM_BLIND_LEVELS.times do |index|
      @tournament.blind_levels.build(
        level: index + 1,
        duration_minutes: 15,
        ante: 0
      )
    end

    @tournament.blind_levels_count =
      Tournament::MINIMUM_BLIND_LEVELS
  end

  def show
    @prize_pool = @tournament.prize_pool
    @buy_in = @tournament.charge_options.find do |option|
      option.buy_in? && option.active?
    end
    @invite_token_access = invitation_show_request?
    @invite_registration = current_user.tournament_registrations.find_by(
      tournament: @tournament
    )
    @show_join_tournament_modal = join_tournament_request? &&
                                  @current_membership&.player? &&
                                  @invite_registration.blank?
    @pending_buy_in_payment = @invite_registration&.registration_payments
                                                   &.joins(:tournament_charge_option)
                                                   &.where(
                                                     status: :pending,
                                                     tournament_charge_options: { kind: :buy_in }
                                                   )
                                                   &.order(created_at: :desc)
                                                   &.first
    @buy_in_payment_modal_open = @invite_registration&.pending? &&
                                 (invitation_show_request? || params[:payment] == "buy_in")
    @invite_url = club_tournament_url(
      @club,
      @tournament,
      invite_token: @tournament.invite_token
    )
    registration_counts = @tournament.tournament_registrations.group(:status).count
    @confirmed_registrations_count = registration_counts.fetch("confirmed", 0)
    @pending_registrations_count = registration_counts.fetch("pending", 0)
    @available_slots_count = [
      @tournament.max_players - @confirmed_registrations_count,
      0
    ].max
  end

  def create
    @tournament = @club.tournaments.build(tournament_params)
    @tournament.status = :draft

    if validate_google_location && create_tournament_with_clock_state
      redirect_to new_club_tournament_charge_options_path(@club, @tournament),
                  notice: "Estrutura do torneio salva. Configure as regras financeiras."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attributes = tournament_params
    @tournament.assign_attributes(attributes)

    if validate_google_location && @tournament.save
      redirect_to edit_club_tournament_charge_options_path(@club, @tournament),
                  notice: "Dados do torneio salvos. Configure as opções financeiras."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tournament.destroy

    redirect_to club_path(@club),
                notice: "Torneio excluído com sucesso.",
                status: :see_other
  end

  def finish
    return redirect_to club_tournament_path(@club, @tournament), alert: "O torneio já foi finalizado." if @tournament.finished?
    return redirect_to club_tournament_path(@club, @tournament), alert: "O torneio precisa estar publicado para ser finalizado." if @tournament.draft?

    ApplicationRecord.transaction do
      @tournament.update!(status: :finished)
      @tournament.clock_state&.update!(status: :finished, started_at: nil, paused_at: nil, overtime_started_at: nil)
    end

    redirect_to club_tournament_path(@club, @tournament), notice: "Torneio finalizado com sucesso."
  rescue ActiveRecord::RecordInvalid
    redirect_to club_tournament_path(@club, @tournament), alert: "Não foi possível finalizar o torneio."
  end

  def join
    TournamentRegistrationConfirmation.call(tournament: @tournament, user: current_user)

    redirect_to club_tournament_path(@club, @tournament, payment: "buy_in"),
                notice: "Presença confirmada. Finalize o pagamento do buy-in para concluir sua inscrição."
  rescue TournamentRegistrationConfirmation::CapacityReached
    redirect_to club_tournament_path(@club, @tournament),
                alert: "Não há mais vagas disponíveis para este torneio."
  end

  private

  def set_member_club
    @club = current_user.clubs.find(params[:club_id])
    @current_membership = @club.club_memberships.find_by!(user: current_user)
  rescue ActiveRecord::RecordNotFound
    return set_invited_tournament if invitation_show_request?

    render plain: "Not found", status: :not_found
  end

  def set_tournament
    return if @tournament.present?

    @tournament = @club.tournaments.find(params[:id])
    return unless invitation_show_request?
    return if @tournament.invite_token == params[:invite_token] && @tournament.invite_link_valid?

    raise ActiveRecord::RecordNotFound
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end



  def authorize_tournament_deletion!
    return if performed?
    return if @current_membership.owner?

    render plain: "Forbidden", status: :forbidden
  end

  def authorize_tournament_finishing!
    return if performed?
    return if @current_membership.owner? || @current_membership.admin?

    render plain: "Forbidden", status: :forbidden
  end

  def authorize_tournament_join!
    return if performed?
    return if @current_membership.player? && @tournament.posted?

    render plain: "Forbidden", status: :forbidden
  end

  def tournament_params
    params.require(:tournament).permit(
      :name,
      :location,
      :google_place_id,
      :max_players,
      :starts_at,
      :blind_levels_count,
      :cover,
      blind_levels_attributes: [
        :id,
        :level,
        :duration_minutes,
        :small_blind,
        :big_blind,
        :ante,
        :_destroy
      ]
    )
  end

  def validate_google_location(place_id = @tournament.google_place_id)
    result = GooglePlaces::PlaceDetails.call(place_id)
    return true if result.valid?

    @tournament.errors.add(:location, "selecione um endereço válido nas sugestões do Google")
    false
  end

  def create_tournament_with_clock_state
    ApplicationRecord.transaction do
      @tournament.save!
      TournamentClockState.create_initial_for!(@tournament)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def authorize_owner!
    return if performed?
    return if @current_membership.owner? || @current_membership.admin?

    render plain: "Forbidden", status: :forbidden
  end

  def invitation_show_request?
    action_name == "show" && params[:invite_token].present?
  end

  def join_tournament_request?
    action_name == "show" && params[:join] == "true"
  end

  def set_invited_tournament
    @tournament = Tournament.find_by!(invite_token: params[:invite_token])
    raise ActiveRecord::RecordNotFound unless @tournament.club_id == params[:club_id].to_i
    raise ActiveRecord::RecordNotFound unless @tournament.id == params[:id].to_i
    raise ActiveRecord::RecordNotFound unless @tournament.invite_link_valid?

    @club = @tournament.club
    @current_membership = @club.club_memberships.find_by(user: current_user)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end
end
