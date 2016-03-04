class CreateCmLogins < ActiveRecord::Migration
  def change
    create_table :cm_logins do |t|
      t.string :connection_id

      t.timestamps
    end
  end
end
