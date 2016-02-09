class AddRemoteIpToBombLogs < ActiveRecord::Migration
  def change
    add_column :bomb_logs, :remote_ip, :string
  end
end
