class CertifiedAgent < ActiveRecord::Base

  # Set accessible fields
  attr_accessible :certified_agent_id, :sub_certified_agent_id, :published, :account_number, :token

  validates :certified_agent_id, presence: true
end
