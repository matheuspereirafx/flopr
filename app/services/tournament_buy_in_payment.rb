class TournamentBuyInPayment
  class InvalidPayment < StandardError; end

  def self.call(registration:, user:)
    new(registration:, user:).call
  end

  def initialize(registration:, user:)
    @registration = registration
    @user = user
  end

  def call
    ApplicationRecord.transaction do
      @registration.with_lock do
        raise InvalidPayment unless @registration.user_id == @user.id
        return @registration if @registration.confirmed?

        buy_in = @registration.tournament.charge_options.find_by(
          kind: :buy_in,
          active: true
        )
        raise InvalidPayment unless buy_in

        RegistrationPayment.create!(
          tournament_registration: @registration,
          tournament_charge_option: buy_in,
          recorded_by: @user,
          amount: buy_in.amount,
          status: :paid,
          provider: "manual",
          payment_method: "manual",
          paid_at: Time.current
        )
        @registration.update!(status: :confirmed)
      end
    end

    @registration
  rescue ActiveRecord::RecordInvalid
    raise InvalidPayment
  end
end
