class AccountsController < ApplicationController

  def api_create
    msisdn = params[:msisdn]
    remote_ip_address = request.remote_ip
    status = "error"

    if !msisdn.blank? && is_a_number?(msisdn) && right_msisdn_length?(msisdn)
      request = Typhoeus::Request.new("http://195.14.0.128:8080/PAYMONEY_WALLET/rest/ussd_create_compte/#{msisdn}", followlocation: true, method: :get)

      request.on_complete do |response|
        if response.success?
          response = (JSON.parse(request.response.body) rescue nil)
          unless response.blank?
            if response["status"].to_s == "1" && response["nom"].to_s == msisdn && response["compte"] != blank?
              status = "1"
              Account.create(msisdn: msisdn, account_number: response["compte"], remote_ip_address: remote_ip_address)
              Log.create(transaction_type: "Creation", phone_number: msisdn, response_log: response.to_s, status: true, remote_ip_address: remote_ip_address)
            else
              Log.create(transaction_type: "Creation", phone_number: msisdn, error_log: response.to_s, status: false, remote_ip_address: remote_ip_address)
            end
          else
            Log.create(transaction_type: "Creation", phone_number: msisdn, error_log: request.response.body, status: false, remote_ip_address: remote_ip_address)
          end
        end
      end

      request.run
    end

    render text: status
  end

  def api_credit_account
    account = params[:account]
    transaction_amount = params[:transaction_amount]
    remote_ip_address = request.remote_ip
    status = "error"

    if !account.blank? && is_a_number?(transaction_amount)
      request = Typhoeus::Request.new("http://195.14.0.128:8080/PAYMONEY_WALLET/rest/ussd_credit_compte/#{account}/#{transaction_amount}", followlocation: true, method: :get)

      request.on_complete do |response|
        if response.success?
          response = (JSON.parse(request.response.body) rescue nil)
          unless response.blank?
            if response["idStatus"].to_s == "1"
              status = "1"
              Log.create(transaction_type: "Crédit de compte", account_number: account, credit_amount: transaction_amount, response_log: response.to_s, status: true, remote_ip_address: remote_ip_address)
            else
              Log.create(transaction_type: "Crédit de compte", account_number: account, credit_amount: transaction_amount, error_log: response.to_s, status: false, remote_ip_address: remote_ip_address)
            end
          else
            Log.create(transaction_type: "Crédit de compte", account_number: account, credit_amount: transaction_amount, error_log: request.response.body, status: false, remote_ip_address: remote_ip_address)
          end
        end
      end

      request.run
    end

    render text: status
  end

  def api_sold
    account = params[:account]
    password = params[:password]
    remote_ip_address = request.remote_ip
    status = "error"

    if !account.blank? && !password.blank?
      request = Typhoeus::Request.new("http://195.14.0.128:8080/PAYMONEY_WALLET/rest/solte_compte/#{account}/#{password}", followlocation: true, method: :get)

      request.on_complete do |response|
        if response.success?
          response = (JSON.parse(request.response.body) rescue nil)
          unless response.blank?
            if response["compte"] != blank?
              status = response["solde"].to_i.to_s
              Log.create(transaction_type: "Solde du compte", account_number: account, response_log: response.to_s, status: true, remote_ip_address: remote_ip_address)
            else
              Log.create(transaction_type: "Solde du compte", account_number: account, error_log: response.to_s, status: false, remote_ip_address: remote_ip_address)
            end
          else
            Log.create(transaction_type: "Solde du compte", account_number: account, error_log: request.response.body, status: false, remote_ip_address: remote_ip_address)
          end
        end
      end

      request.run
    end

    render text: status
  end

  def api_checkout_account
    account = params[:account]
    password = params[:password]
    transaction_amount = params[:transaction_amount]
    remote_ip_address = request.remote_ip
    status = "error"

    if !account.blank? && !password.blank? && is_a_number?(transaction_amount)
      request = Typhoeus::Request.new("http://195.14.0.128:8080/PAYMONEY_WALLET/rest/ussd_debit_compte/#{account}/#{password}/#{transaction_amount}", followlocation: true, method: :get)

      request.on_complete do |response|
        if response.success?
          response = (JSON.parse(request.response.body) rescue nil)
          unless response.blank?
            if response["idStatus"].to_s == "0"
              status = "1"
              Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, response_log: response.to_s, status: true, remote_ip_address: remote_ip_address)
              # add otp
            else
              Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, error_log: response.to_s, status: false, remote_ip_address: remote_ip_address)
            end
          else
            Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, error_log: request.response.body, status: false, remote_ip_address: remote_ip_address)
          end
        end
      end

      request.run
    end

    render text: status
  end

  def api_validate_checkout
    pin = params[:pin]
    transaction_id = params[:transaction_id]
    remote_ip_address = request.remote_ip
    status = "error"

    if !pin.blank? && !transaction_id.blank?
      request = Typhoeus::Request.new("http://195.14.0.128:8080/PAYMONEY_WALLET/rest/otp_active/#{pin}/#{transaction_id}", followlocation: true, method: :get)

      request.on_complete do |response|
        if response.success?
          response = (JSON.parse(request.response.body) rescue nil)
          unless response.blank?
            if response["otpStatus"].to_s == "true"
              status = "1"
              Log.create(transaction_type: "Validation de paiement", otp: transaction_id, pin: pin, response_log: response.to_s, status: true, remote_ip_address: remote_ip_address)
            else
              Log.create(transaction_type: "Validation de paiement", error_log: response.to_s, status: false, remote_ip_address: remote_ip_address)
            end
          else
            Log.create(transaction_type: "Validation de paiement", error_log: request.response.body, status: false, remote_ip_address: remote_ip_address)
          end
        end
      end

      request.run
    end

    render text: status
  end

  # Utils
  def is_a_number?(msisdn)
    msisdn_status = true
  	if msisdn.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil
  	  msisdn_status = false
  	end

  	return msisdn_status
  end

  def right_msisdn_length?(msisdn)
    msisdn_status = true
    if msisdn.length != 8
      msisdn_status = false
    end

    return msisdn_status
  end

end
