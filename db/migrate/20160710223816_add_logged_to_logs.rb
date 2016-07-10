class AddLoggedToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :logged, :boolean
  end
end
