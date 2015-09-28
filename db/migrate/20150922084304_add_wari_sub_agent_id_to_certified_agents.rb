class AddWariSubAgentIdToCertifiedAgents < ActiveRecord::Migration
  def change
    add_column :certified_agents, :wari_sub_agent_id, :string
  end
end
