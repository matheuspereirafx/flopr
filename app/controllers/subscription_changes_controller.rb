class SubscriptionChangesController < ApplicationController
  before_action :set_club_and_membership
  before_action :authorize_plan_management!
  before_action :set_current_subscription, only: %i[new create]

  def new
    @selected_plan = selected_plan
    @available_plans = available_downgrade_plans
  end

  def create
    new_plan = Plan.find(subscription_change_params[:new_plan_id])
    return render plain: "Plano indisponível.", status: :unprocessable_entity unless new_plan.active?

    subscription_change = @club.subscription_changes.new(
      club_subscription: @current_subscription,
      current_plan: @current_subscription.plan,
      new_plan: new_plan,
      requested_by: current_user,
      change_type: :downgrade,
      status: :pending,
      effective_at: @current_subscription.expires_at
    )

    subscription_change.save!

    redirect_to club_subscriptions_path,
                notice: "Downgrade agendado para a próxima renovação."
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
    @available_plans = available_downgrade_plans
    @error_message = error_message(error)
    render :new, status: :unprocessable_entity
  end

  def destroy
    subscription_change = @club.subscription_changes.pending.first
    return head :not_found unless subscription_change

    subscription_change.update!(status: :canceled, canceled_at: Time.current)

    redirect_to club_subscriptions_path,
                notice: "Downgrade cancelado."
  rescue ActiveRecord::RecordInvalid
    render plain: "Não foi possível cancelar o downgrade.", status: :unprocessable_entity
  end

  private

  def set_club_and_membership
    @current_membership = current_user.club_memberships.find_by(club_id: params[:club_id])
    return head :not_found unless @current_membership

    @club = @current_membership.club
  end

  def authorize_plan_management!
    return if performed? || @current_membership.owner? || @current_membership.admin?

    head :forbidden
  end

  def set_current_subscription
    @current_subscription = @club.active_club_subscription
    return if @current_subscription.present? && @current_subscription.expires_at.present?

    return render plain: "A assinatura atual não possui data de expiração.", status: :unprocessable_entity if action_name == "create"

    redirect_to club_subscriptions_path,
                alert: "A assinatura atual não possui data de expiração."
  end

  def available_downgrade_plans
    plans = if @selected_plan
              [@selected_plan]
            else
              Plan.active.where.not(id: @current_subscription.plan_id)
            end

    plans.select do |plan|
      @current_subscription.plan.downgrade_to?(plan)
    end
  end

  def selected_plan
    return if params[:plan_id].blank?

    Plan.active.find(params[:plan_id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def subscription_change_params
    params.require(:subscription_change).permit(:new_plan_id)
  end

  def error_message(error)
    return error.record.errors.full_messages.to_sentence if error.respond_to?(:record) && error.record

    "Já existe uma alteração pendente para este clube."
  end
end
