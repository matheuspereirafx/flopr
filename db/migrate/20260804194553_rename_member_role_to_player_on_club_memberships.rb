class RenameMemberRoleToPlayerOnClubMemberships < ActiveRecord::Migration[8.1]
  class MigrationClubMembership < ApplicationRecord
    self.table_name = "club_memberships"
  end

  def up
    MigrationClubMembership.where(role: "member").update_all(role: "player")

    change_column_default :club_memberships,
                          :role,
                          from: "member",
                          to: "player"
  end

  def down
    MigrationClubMembership.where(role: "player").update_all(role: "member")

    change_column_default :club_memberships,
                          :role,
                          from: "player",
                          to: "member"
  end
end
