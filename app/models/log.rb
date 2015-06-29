class Log < ActiveRecord::Base

  # Set accessible fields
  attr_accessible :transaction_type, :phone_number, :account_number, :credit_amount, :checkout_amount, :otp, :pin, :status, :error_log, :response_log, :remote_ip_address
end
