module ApplicationHelper
  def tournament_area?
    %w[
      blind_levels
      tournament_charge_options
      tournament_clocks
      tournament_invitation_links
      tournament_invite_links
      tournament_registrations
      tournaments
    ].include?(controller_name)
  end

  def tournament_navigation_items(club:, tournament:, membership:, registration:, active_page:)
    return [overview_navigation_item(club, tournament, active_page)] unless membership

    items = [
      overview_navigation_item(club, tournament, active_page),
      navigation_item("Jogadores", "icons/Iconplayer.svg", :players, active_page,
                      club_tournament_registrations_path(club, tournament)),
      navigation_item("Relógio", "icons/icontimermenu.svg", :clock, active_page,
                      club_tournament_clock_path(club, tournament))
    ]

    if membership.owner? || membership.admin?
      items.insert(2, navigation_item("Pagamentos", "icons/iconcash.png", :payments, active_page))
      items << navigation_item(
        "Configurações",
        "icons/iconconfiguracoes.svg",
        :settings,
        active_page,
        edit_club_tournament_path(club, tournament)
      )
    elsif membership.dealer?
      items.insert(2, navigation_item("Recargas", "icons/iconcash.png", :reloads, active_page))
    elsif registration&.confirmed?
      items.insert(2, navigation_item("Histórico", "icons/iconcash.png", :history, active_page))
      items.insert(3, navigation_item("Solicitações", "icons/iconcash.png", :requests, active_page))
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
