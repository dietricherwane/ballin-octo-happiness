class AddPaymoneyValidationIdToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :paymoney_validation_id, :string
  end
end
