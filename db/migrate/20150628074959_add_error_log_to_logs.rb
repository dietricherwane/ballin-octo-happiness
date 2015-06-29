class AddErrorLogToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :error_log, :text
  end
end
