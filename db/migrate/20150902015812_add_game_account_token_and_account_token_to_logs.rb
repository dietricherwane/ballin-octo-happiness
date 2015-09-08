class AddGameAccountTokenAndAccountTokenToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :game_account_token, :string
    add_column :logs, :account_token, :string
  end
end
