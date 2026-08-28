class TournamentRegistrationConfirmation
  class CapacityReached < StandardError; end

  def self.call(tournament:, user:)
    new(tournament:, user:).call
  end

  def initialize(tournament:, user:)
    @tournament = tournament
    @user = user
  end

  def call
    @tournament.with_lock do
      registration = find_or_create_registration!
      return registration if registration.confirmed?

      raise CapacityReached if @tournament.finished?
      raise CapacityReached if @tournament.capacity_reached?

      registration.update!(status: :pending)
      create_pending_buy_in_payment!(registration)
      registration
    end
  end

  private

  def find_or_create_registration!
    @user.club_memberships.find_or_create_by!(club: @tournament.club) do |membership|
      membership.role = :player
    end

    TournamentRegistration.find_or_create_by!(tournament: @tournament, user: @user) do |registration|
      registration.status = :pending
    end
  end

  def create_pending_buy_in_payment!(registration)
    buy_in = @tournament.charge_options.find_by(kind: :buy_in, active: true)
    return if buy_in.blank?
    return if registration.registration_payments.exists?(tournament_charge_option: buy_in)

    registration.registration_payments.create!(
      tournament_charge_option: buy_in,
      recorded_by: @user,
      amount: buy_in.amount,
      status: :pending,
      provider: "manual",
      payment_method: "manual"
    )
  end
end
