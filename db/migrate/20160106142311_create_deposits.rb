class CreateDeposits < ActiveRecord::Migration
  def change
    create_table :deposits do |t|
      t.string :game_token
      t.string :pos_id
      t.string :agent
      t.string :sub_agent
      t.string :paymoney_account
      t.text :deposit_request
      t.text :deposit_response
      t.string :deposit_day
      t.float :deposit_amount
      t.string :transaction_id
      t.boolean :deposit_made

      t.timestamps
    end
  end
end
