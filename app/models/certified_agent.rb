class CertifiedAgent < ActiveRecord::Base

  # Set accessible fields
  attr_accessible :certified_agent_id, :published

  validates :certified_agent_id, presence: true
end
