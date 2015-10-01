class Parameter < ActiveRecord::Base
  # Set accessible fields
  attr_accessible :paymoney_wallet_url, :hub_front_office_url
end
