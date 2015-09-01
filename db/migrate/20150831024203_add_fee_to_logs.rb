class AddFeeToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :fee, :float
  end
end
