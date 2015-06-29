class Account < ActiveRecord::Base

  # Set accessible fields
  attr_accessible :msisdn, :account_number, :remote_ip_address, :password, :salt

  private
    def encrypt_password
      self.password = Digest::SHA2.hexdigest(salt + password)
    end

    def msisdn_not_a_number?
    	if msisdn.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil
    	  errors.add(:msisdn, " doit être numérique")
    	end
    end

    def right_msisdn_length?
      if msisdn.length != 8
        errors.add(:msisdn, " doit être sur 8 caractères")
      end
    end
end
