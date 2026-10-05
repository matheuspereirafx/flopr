class ClubSubscriptionsController < ApplicationController
  skip_before_action :authenticate_user!, only: :new

  before_action :set_plan, only: :new
  before_action :set_requested_club, only: :create
  before_action :authorize_owner!, only: :create

  def new
    redirect_to new_user_session_path(plan_id: params[:plan_id]) unless user_signed_in?

    @owned_clubs = current_user.owned_clubs.order(:name) if user_signed_in?
  end

  def create
    plan = find_plan_for_contract
    return head :not_found unless plan
    return head :unprocessable_entity unless plan.active?

    subscription = ClubSubscription.new(
      club: @club,
      plan: plan,
      owner: current_user,
      status: :active,
      billing_period: plan.billing_period
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
    return if performed? || @current_membership.owner?

    head :forbidden
  end

  def subscription_params
    params.slice(:plan_id, :club_id).permit(:plan_id, :club_id)
  end
end
