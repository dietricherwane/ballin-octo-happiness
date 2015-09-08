class AddAccountNumberToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :account_number, :string
  end
end
