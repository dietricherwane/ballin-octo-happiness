class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :msisdn, limit: 13
      t.string :account_number
      t.string :remote_ip_address
      t.string :password

      t.timestamps
    end
  end
end
