class AddLoggingFieldsToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :logging_request, :text
    add_column :logs, :logging_response, :string, limit: 2
  end
end
