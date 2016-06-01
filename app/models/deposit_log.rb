class DepositLog < ActiveRecord::Base
  attr_accessible :game_token, :pos_id, :deposit_request, :deposit_response, :session_id
end
