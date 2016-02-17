class CreateBombLogs < ActiveRecord::Migration
  def change
    create_table :bomb_logs do |t|
      t.text :sent_url

      t.timestamps
    end
  end
end
