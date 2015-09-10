class AddAAccountTransferAndBAccountTransferToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :a_account_transfer, :string
    add_column :logs, :b_account_transfer, :string
  end
end
