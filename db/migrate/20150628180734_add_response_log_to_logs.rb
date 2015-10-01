class AddResponseLogToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :response_log, :text
  end
end
