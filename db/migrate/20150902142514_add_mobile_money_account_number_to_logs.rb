class AddMobileMoneyAccountNumberToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :mobile_money_account_number, :string
  end
end
