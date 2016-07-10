class Log < ActiveRecord::Base

  # Set accessible fields
  attr_accessible :transaction_type, :phone_number, :account_number, :credit_amount, :checkout_amount, :otp, :pin, :status, :error_log, :response_log, :remote_ip_address, :agent, :sub_agent, :transaction_id, :fee, :thumb, :game_account_token, :account_token, :mobile_money_account_number, :a_account_transfer, :b_account_transfer, :bet_placed, :bet_placed_at, :bet_validated, :bet_validated_at, :bet_paid_back, :bet_paid_back_at, :paymoney_validation_id, :logging_request, :logging_response
end
