class FeeType < ActiveRecord::Base

  # Set accessible fields
  attr_accessible :name, :token

  # Relationships
  has_many :fees
end
