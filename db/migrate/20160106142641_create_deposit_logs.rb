class CreateDepositLogs < ActiveRecord::Migration
  def change
    create_table :deposit_logs do |t|
      t.string :game_token
      t.string :pos_id
      t.text :deposit_request
      t.text :deposit_response
      t.string :session_id

      t.timestamps
    end
  end
end
