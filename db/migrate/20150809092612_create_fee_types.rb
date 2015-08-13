class CreateFeeTypes < ActiveRecord::Migration
  def change
    create_table :fee_types do |t|
      t.string :name
      t.string :token

      t.timestamps
    end
  end
end
