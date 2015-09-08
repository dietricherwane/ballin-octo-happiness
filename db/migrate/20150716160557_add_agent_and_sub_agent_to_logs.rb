class AddAgentAndSubAgentToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :agent, :string
    add_column :logs, :sub_agent, :string
  end
end
