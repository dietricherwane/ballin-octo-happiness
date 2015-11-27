class AddFieldsToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :bet_placed, :boolean
    add_column :logs, :bet_placed_at, :datetime
    add_column :logs, :bet_validated, :boolean
    add_column :logs, :bet_validated_at, :datetime
    add_column :logs, :bet_paid_back, :boolean
    add_column :logs, :bet_paid_back_at, :datetime
  end
end
