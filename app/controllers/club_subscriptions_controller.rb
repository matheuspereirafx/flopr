class ClubSubscriptionsController < ApplicationController
  skip_before_action :authenticate_user!, only: :new

  before_action :set_plan, only: :new
  before_action :set_requested_club, only: :create
  before_action :authorize_owner!, only: :create

  def index
    @clubs = manageable_clubs
                             .includes(active_club_subscription: :plan,
                                       pending_subscription_change: :new_plan)
                             .order(:name)
  end

  def new
    redirect_to new_user_session_path(plan_id: params[:plan_id]) unless user_signed_in?

    @manageable_clubs = manageable_clubs
                             .includes(active_club_subscription: :plan)
                             .order(:name) if user_signed_in?
    @billing_options = billing_options
  end

  def create
    plan = find_plan_for_contract
    return head :not_found unless plan
    return head :unprocessable_entity unless plan.active?
    if @club.active_club_subscription&.plan_id == plan.id
      redirect_to club_subscriptions_path,
                  alert: "Este clube já possui este plano ativo."
      return
    end

    current_subscription = @club.active_club_subscription
    if current_subscription&.plan&.price.to_d > plan.price.to_d
      return head :unprocessable_entity
    end

    subscription = ClubSubscription.new(
      club: @club,
      plan: plan,
      owner: current_user,
      status: :active,
      billing_period: plan.billing_period,
      expires_at: plan.subscription_expires_at
    )

    ClubSubscription.transaction do
      @club.active_club_subscription&.update!(status: :canceled)
      subscription.save!
    end

    redirect_to clubs_path, notice: "Plano contratado com sucesso."
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  private

  def set_plan
    @plan = Plan.active.find(subscription_params[:plan_id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def find_plan_for_contract
    Plan.find(subscription_params[:plan_id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def set_requested_club
    return head :unprocessable_entity if subscription_params[:club_id].blank?

    membership = current_user.club_memberships.find_by(club_id: subscription_params[:club_id])
    return head :not_found unless membership

    @club = membership.club
    @current_membership = membership
  end

  def authorize_owner!
    return if performed? || @current_membership.owner? || @current_membership.admin?

    head :forbidden
  end

  def manageable_clubs
    Club.joins(:club_memberships)
        .where(club_memberships: { user_id: current_user.id, role: %i[owner admin] })
  end

  def billing_options
    base_name = @plan.name.delete_suffix(" Anual")

    Plan.active
        .where(name: [base_name, "#{base_name} Anual"])
        .order(:billing_period)
  end

  def subscription_params
    params.slice(:plan_id, :club_id).permit(:plan_id, :club_id)
  end
end
