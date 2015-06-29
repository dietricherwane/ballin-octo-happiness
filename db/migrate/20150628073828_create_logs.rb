class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :transaction_type
      t.string :phone_number, limit: 13
      t.string :credit_amount
      t.string :checkout_amount
      t.string :otp
      t.string :pin
      t.boolean :status

      t.timestamps
    end
  end
end
