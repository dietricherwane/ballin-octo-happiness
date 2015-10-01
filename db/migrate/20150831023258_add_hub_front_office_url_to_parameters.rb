class AddHubFrontOfficeUrlToParameters < ActiveRecord::Migration
  def change
    add_column :parameters, :hub_front_office_url, :string
  end
end
