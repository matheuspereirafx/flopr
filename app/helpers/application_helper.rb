module ApplicationHelper
  def tournament_area?
    %w[
      blind_levels
      tournament_charge_options
      tournament_clocks
      tournament_invitation_links
      tournament_invite_links
      tournament_registrations
      tournament_transactions
      tournament_recharges
      tournaments
    ].include?(controller_name)
  end

  def tournament_navigation_items(club:, tournament:, membership:, registration:, active_page:)
    return [overview_navigation_item(club, tournament, active_page)] unless membership

    items = [
      overview_navigation_item(club, tournament, active_page),
      navigation_item("Relógio", "icons/timericon.png", :clock, active_page,
                      club_tournament_clock_path(club, tournament))
    ]

    if club.plan_allows?(:guest_list)
      items.insert(
        1,
        navigation_item("Jogadores", "icons/Iconplayer.svg", :players, active_page,
                        club_tournament_registrations_path(club, tournament))
      )
    end

    if membership.owner? || membership.admin?
      if club.plan_allows?(:transactions)
        items.insert(
          2,
          navigation_item(
            "Transações",
            "icons/iconcash.png",
            :transactions,
            active_page,
            club_tournament_transactions_path(club, tournament)
          )
        )
      end
      if registration&.confirmed? && club.plan_allows?(:recharges)
        items.insert(
          3,
          navigation_item(
            "Recargas",
            "icons/iconrecharge.svg",
            :recharges,
            active_page,
            club_tournament_recharges_path(club, tournament)
          )
        )
      end
      items << navigation_item(
        "Configurações",
        "icons/iconconfiguracoes.svg",
        :settings,
        active_page,
        edit_club_tournament_path(club, tournament)
      )
    elsif membership.dealer? && club.plan_allows?(:recharges)
      items.insert(2, navigation_item("Recargas", "icons/iconrecharge.svg", :reloads, active_page))
    elsif registration&.confirmed? && club.plan_allows?(:recharges)
      items.insert(
        2,
        navigation_item(
          "Recargas",
          "icons/iconrecharge.svg",
          :recharges,
          active_page,
          club_tournament_recharges_path(club, tournament)
        )
      )
    end

    items
  end

  private

  def overview_navigation_item(club, tournament, active_page)
    navigation_item(
      "Visão geral",
      "icons/iconoverview.svg",
      :overview,
      active_page,
      club_tournament_path(club, tournament)
    )
  end

  def navigation_item(label, icon, key, active_page, path = nil)
    {
      label: label,
      icon: icon,
      key: key,
      path: path,
      active: key == active_page,
      disabled: path.blank?
    }
  end
end
