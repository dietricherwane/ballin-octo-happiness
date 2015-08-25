class AddSubCertifiedAgentIdToCertifiedAgents < ActiveRecord::Migration
  def change
    add_column :certified_agents, :sub_certified_agent_id, :string
  end
end
