class ChangeDefaultTournamentStatusToPosted < ActiveRecord::Migration[8.1]
  class MigrationTournament < ApplicationRecord
    self.table_name = "tournaments"
  end

  def up
    MigrationTournament.where(status: "draft").update_all(status: "posted")

    change_column_default :tournaments,
                          :status,
                          from: "draft",
                          to: "posted"
  end

  def down
    change_column_default :tournaments,
                          :status,
                          from: "posted",
                          to: "draft"
  end
end
