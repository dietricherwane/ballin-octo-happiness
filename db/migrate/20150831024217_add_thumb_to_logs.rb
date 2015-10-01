class AddThumbToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :thumb, :float
  end
end
