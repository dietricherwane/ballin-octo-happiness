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
    unlogged_transactions("Crédit de compte", { transaction_type: "Crédit de compte", account_number: transaction.account_number, credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, thumb: transaction.thumb, fee: transaction.fee })
  end

  def unlogged_credit_validations
    unlogged_transactions("Validation de crédit", { transaction_type: "Validation de crédit", account_number: transaction.account_number, credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, otp: transaction.otp, pin: transaction.pin })
  end

  def unlogged_withdrawals
    unlogged_transactions("Débit du compte", { transaction_type: "Débit du compte", account_number: transaction.account_number, checkout_amount: transaction.checkout_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, thumb: transaction.thumb, fee: transaction.fee, otp: transaction.otp })
  end

  def unlogged_withdrawal_validations
    unlogged_transactions("Validation de débit", { transaction_type: "Validation de débit", account_number: transaction.account_number, checkout_amount: transaction.checkout_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, otp: transaction.otp, pin: transaction.pin })
  end

  def unlogged_funds_ascending
    unlogged_transactions("Remontée de fonds", { transaction_type: "Remontée de fonds", checkout_amount: transaction.checkout_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, agent: transaction.agent, sub_agent: transaction.sub_agent, transaction_id: transaction.transaction_id, fee: transaction.fee })
  end

  def unlogged_transfers
    unlogged_transactions("Transfert de crédit", { transaction_type: "Transfert de crédit", credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, a_account_transfer: transaction.a_account_transfer, b_account_transfer: transaction.b_account_transfer, transaction_id: transaction.transaction_id, fee: transaction.fee })
  end

  def unlogged_deposits
    unlogged_transactions("Deposit", { transaction_type: "Deposit", credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, transaction_id: transaction.transaction_id, account_token: transaction.account_token })
  end

  def unlogged_cashin_mobile_money
    unlogged_transactions("Cashin mobile money", { transaction_type: "Cashin mobile money", credit_amount: transaction.credit_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, transaction_id: transaction.transaction_id, account_number: transaction.account_number, mobile_money_account_number: transaction.mobile_money_account, fee: transaction.fee })
  end

  def unlogged_cashout_mobile_money
    unlogged_transactions("Cashout mobile money", { transaction_type: "Cashout mobile money", checkout_amount: transaction.checkout_amount, status: transaction.status, remote_ip_address: transaction.remote_ip_address, transaction_id: transaction.transaction_id, account_number: transaction.account_number, mobile_money_account_number: transaction.mobile_money_account, fee: transaction.fee })
  end

  def unlogged_transactions(transaction_type, notification_object)
    transactions = Log.where("transaction_type = '#{transaction_type}' AND logging_response != '1'")

    unless transactions.blank?
      transactions.each do |transaction|
        response = Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/377777f5968800cd/paymoney_wallet/store_unlogged_transactions", params: notification_object).body rescue '0'
        transaction.update_attribute(:logging_response, response)
      end
    end
  end

end
