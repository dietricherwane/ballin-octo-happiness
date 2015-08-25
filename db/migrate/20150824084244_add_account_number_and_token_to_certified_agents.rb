class AddAccountNumberAndTokenToCertifiedAgents < ActiveRecord::Migration
  def change
    add_column :certified_agents, :account_number, :string
    add_column :certified_agents, :token, :string
  end
end
