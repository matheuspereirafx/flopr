require "securerandom"

class AddInviteTokenToTournaments < ActiveRecord::Migration[8.1]
  class MigrationTournament < ApplicationRecord
    self.table_name = "tournaments"
  end

  def up
    add_column :tournaments, :invite_token, :string

    MigrationTournament.reset_column_information
    MigrationTournament.where(invite_token: nil).find_each do |tournament|
      token = SecureRandom.urlsafe_base64(24)
      token = SecureRandom.urlsafe_base64(24) while MigrationTournament.exists?(invite_token: token)

      tournament.update_columns(invite_token: token)
    end

    change_column_null :tournaments, :invite_token, false
    add_index :tournaments, :invite_token, unique: true
  end

  def down
    remove_index :tournaments, :invite_token
    remove_column :tournaments, :invite_token
  end
end
