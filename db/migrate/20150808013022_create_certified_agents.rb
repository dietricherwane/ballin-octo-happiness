class CreateCertifiedAgents < ActiveRecord::Migration
  def change
    create_table :certified_agents do |t|
      t.string :certified_agent_id
      t.boolean :published

      t.timestamps
    end
  end
end
