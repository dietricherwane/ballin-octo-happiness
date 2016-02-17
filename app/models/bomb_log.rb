class BombLog < ActiveRecord::Base
  # Set accessible fields
  attr_accessible :sent_url, :remote_ip
end
