class AddTransactionIdToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :transaction_id, :string
  end
end
