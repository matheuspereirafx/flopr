class TournamentChargeOptionsController < ApplicationController
  before_action :set_member_club
  before_action :authorize_owner!
  before_action :set_tournament
  before_action :load_charge_options

  def new
  end

  def create
    save_configuration
  end

  def edit
  end

  def update
    save_configuration
  end

  private

  def set_member_club
    @club = current_user.clubs.find(params[:club_id])
    @current_membership = @club.club_memberships.find_by!(user: current_user)
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end

  def authorize_owner!
    return if performed? || @current_membership.owner?

    render plain: "Forbidden", status: :forbidden
  end

  def set_tournament
    return if performed?

    @tournament = @club.tournaments.find(params[:tournament_id])
  rescue ActiveRecord::RecordNotFound
    render plain: "Not found", status: :not_found
  end

  def load_charge_options
    return if performed?

    @charge_options = TournamentChargeOption::KINDS.index_with do |kind|
      @tournament.charge_options.find { |option| option.kind == kind } ||
        @tournament.charge_options.build(kind: kind, active: required_kind?(kind))
    end
    @period_end_level = configured_period_end_level
  end

  def save_configuration
    assign_charge_options

    if charge_options_valid? && tournament_valid?
      ApplicationRecord.transaction do
        @charge_options.each_value(&:save!)
        @tournament.update!(status: :posted)
      end

      redirect_to club_path(@club),
                  notice: "Regras financeiras do torneio salvas com sucesso."
    else
      @tournament.status = @tournament.status_in_database
      render action_name == "create" ? :new : :edit,
             status: :unprocessable_entity
    end
  end

  def assign_charge_options
    selected_period_end = @tournament.blind_levels.find_by(
      id: financial_configuration_params[:period_end_level_id]
    )

    TournamentChargeOption::KINDS.each do |kind|
      option = @charge_options.fetch(kind)
      attributes = charge_option_attributes(kind)
      option.assign_attributes(attributes)
      option.active = required_kind?(kind) || ActiveModel::Type::Boolean.new.cast(attributes[:active])
      assign_availability_period(option, selected_period_end)
    end

    @period_end_level = selected_period_end
  end

  def assign_availability_period(option, period_end_level)
    option.available_from_level = nil
    option.available_until_level = nil
    return if option.buy_in? || !option.active?

    rebuy_start_level = @tournament.blind_levels.first

    if option.addon?
      option.available_from_level = period_end_level
    else
      option.available_from_level = rebuy_start_level
      option.available_until_level = period_end_level
    end
  end

  def charge_options_valid?
    @charge_options.values.map(&:valid?).all?
  end

  def tournament_valid?
    @tournament.status = :posted
    @tournament.valid?
  end

  def financial_configuration_params
    @financial_configuration_params ||= params.require(:financial_configuration).permit(
      :period_end_level_id,
      charge_options: TournamentChargeOption::KINDS.index_with do
        %i[active amount chip_amount]
      end
    )
  end

  def charge_option_attributes(kind)
    values = financial_configuration_params.fetch(:charge_options, {})[kind] || {}
    values.slice(:active, :amount, :chip_amount)
  end

  def required_kind?(kind)
    kind == "buy_in"
  end

  def configured_period_end_level
    @charge_options.values.filter_map do |option|
      option.addon? ? option.available_from_level : option.available_until_level
    end.first
  end

end
