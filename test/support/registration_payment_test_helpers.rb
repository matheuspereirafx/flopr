module RegistrationPaymentTestHelpers
  def payment_create_user(email)
    username = email.split("@").first.gsub(/[^a-zA-Z0-9_.]/, "_")
    User.create!(
      email: email,
      password: "password123",
      name: email.split("@").first,
      username: username
    )
  end

  def payment_create_club(name: "Poker House")
    Club.create!(name: name)
  end

  def payment_create_membership(user:, club:, role:)
    ClubMembership.create!(user: user, club: club, role: role)
  end

  def payment_create_tournament(club:, name: "Friday Poker Night")
    tournament = club.tournaments.build(
      name: name,
      location: "Rua das Flores, 123",
      max_players: 24,
      starts_at: 2.days.from_now,
      status: :draft
    )

    5.times do |index|
      level = index + 1
      tournament.blind_levels.build(
        level: level,
        duration_minutes: 15,
        small_blind: level * 100,
        big_blind: level * 200,
        ante: 0
      )
    end

    tournament.save!
    tournament
  end

  def payment_create_charge_option(tournament:, kind: :buy_in, amount: 50, active: true)
    tournament.charge_options.create!(
      kind: kind,
      active: active,
      amount: amount,
      chip_amount: 10_000
    )
  end

  def payment_create_registration(tournament:, user:, status: :confirmed)
    TournamentRegistration.create!(
      tournament: tournament,
      user: user,
      status: status
    )
  end

  def payment_create_registration_payment(tournament:, user:, recorded_by:, status: :paid,
                                          kind: :buy_in, amount: 50)
    registration = tournament.tournament_registrations.find_by!(user: user)
    charge_option = tournament.charge_options.find_by!(kind: kind)

    RegistrationPayment.create!(
      tournament_registration: registration,
      tournament_charge_option: charge_option,
      amount: amount,
      status: status,
      provider: "gateway",
      payment_method: "pix",
      recorded_by: recorded_by
    )
  end

  def transactions_path(club, tournament, query = {})
    path = "/clubs/#{club.id}/tournaments/#{tournament.id}/transactions"
    query_string = Rack::Utils.build_query(query)

    query_string.empty? ? path : "#{path}?#{query_string}"
  end
end
