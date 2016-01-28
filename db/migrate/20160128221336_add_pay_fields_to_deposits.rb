class AddPayFieldsToDeposits < ActiveRecord::Migration
  def change
    add_column :deposits, :paymoney_request, :text
    add_column :deposits, :paymoney_response, :text
  end
end
