class AddRemoteIpAddressToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :remote_ip_address, :string
  end
end
