class Deposit < ActiveRecord::Base
  attr_accessible :game_token, :pos_id, :agent, :sub_agent, :paymoney_account, :deposit_request, :deposit_response, :deposit_day, :deposit_amount, :paymoney_request, :paymoney_response, :paymoney_transaction_id, :deposit_made, :transaction_id
end
