class LogsController < ApplicationController

  def send_unlogged_transactions
    unlogged_credits
    unlogged_credit_validations
    unlogged_withdrawals
    unlogged_withdrawal_validations
    unlogged_funds_ascending
    unlogged_transfers
    unlogged_deposits
    unlogged_cashin_mobile_money
    unlogged_cashout_mobile_money
  end

  def unlogged_credits
    transactions = Log.where("transaction_type = 'Credit de compte' AND logged IS NOT TRUE")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: { transaction_type: "Credit de compte", account_number: transaction.account_number, credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, thumb: transaction.thumb, fee: transaction.fee, created_at: transaction.created_at }).body rescue '0'
        transaction.update_attributes(logging_response: response, logged: (response == '1' ? true : false))
      end
    end
  end

  def unlogged_credit_validations
    transactions = Log.where("transaction_type = 'Validation de credit' AND logged IS NOT TRUE")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: { transaction_type: "Validation de credit", account_number: transaction.account_number, credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, otp: transaction.otp, pin: transaction.pin, created_at: transaction.created_at }).body rescue '0'
        transaction.update_attributes(logging_response: response, logged: (response == '1' ? true : false))
      end
    end
  end

  def unlogged_withdrawals
    transactions = Log.where("transaction_type = 'Debit du compte' AND logged IS NOT TRUE")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: { transaction_type: "Debit du compte", account_number: transaction.account_number, checkout_amount: transaction.checkout_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, thumb: transaction.thumb, fee: transaction.fee, otp: transaction.otp, created_at: transaction.created_at }).body rescue '0'
        transaction.update_attributes(logging_response: response, logged: (response == '1' ? true : false))
      end
    end
  end

  def unlogged_withdrawal_validations
    transactions = Log.where("transaction_type = 'Validation de debit' AND logged IS NOT TRUE")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: { transaction_type: "Validation de debit", account_number: transaction.account_number, checkout_amount: transaction.checkout_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, otp: transaction.otp, pin: transaction.pin, created_at: transaction.created_at }).body rescue '0'
        transaction.update_attributes(logging_response: response, logged: (response == '1' ? true : false))
      end
    end
  end

  def unlogged_funds_ascending
    transactions = Log.where("transaction_type = 'Remontee de fonds' AND logged IS NOT TRUE")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: { transaction_type: "Remontee de fonds", checkout_amount: transaction.checkout_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, fee: transaction.fee, created_at: transaction.created_at }).body rescue '0'
        transaction.update_attributes(logging_response: response, logged: (response == '1' ? true : false))
      end
    end
  end

  def unlogged_transfers
    transactions = Log.where("transaction_type = 'Transfert de credit' AND logged IS NOT TRUE")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: { transaction_type: "Transfert de credit", credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, a_account_transfer: transaction.a_account_transfer, b_account_transfer: transaction.b_account_transfer, transaction_id: transaction.transaction_id, fee: transaction.fee, created_at: transaction.created_at }).body rescue '0'
        transaction.update_attributes(logging_response: response, logged: (response == '1' ? true : false))
      end
    end
  end

  def unlogged_deposits
    transactions = Log.where("transaction_type = 'Deposit' AND logged IS NOT TRUE")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: { transaction_type: "Deposit", credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, transaction_id: transaction.transaction_id, account_token: transaction.account_token, created_at: transaction.created_at }).body rescue '0'
        transaction.update_attributes(logging_response: response, logged: (response == '1' ? true : false))
      end
    end
  end

  def unlogged_cashin_mobile_money
    transactions = Log.where("transaction_type = 'Cashin mobile money' AND logged IS NOT TRUE")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: { transaction_type: "Cashin mobile money", credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, transaction_id: transaction.transaction_id, account_number: transaction.account_number, mobile_money_account_number: transaction.mobile_money_account, fee: transaction.fee, created_at: transaction.created_at }).body rescue '0'
        transaction.update_attributes(logging_response: response, logged: (response == '1' ? true : false))
      end
    end
  end

  def unlogged_cashout_mobile_money
    transactions = Log.where("transaction_type = 'Cashout mobile money' AND logged IS NOT TRUE")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: { transaction_type: "Cashout mobile money", checkout_amount: transaction.checkout_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, transaction_id: transaction.transaction_id, account_number: transaction.account_number, mobile_money_account_number: transaction.mobile_money_account, fee: transaction.fee, created_at: transaction.created_at }).body rescue '0'
        transaction.update_attributes(logging_response: response, logged: (response == '1' ? true : false))
      end
    end
  end

end
