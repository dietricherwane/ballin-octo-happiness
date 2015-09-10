class AccountsController < ApplicationController

  #before_filter :check_agent_and_sub_agent_relationship, only: [:api_ascent, :api_validate_checkout, :api_credit_account, :api_sold, :api_checkout_account]

  @paymoney_wallet_url = (Parameter.first.paymoney_wallet_url rescue "")

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
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "500"
    transaction_status = false

    account_token = check_account_number(account)

    if account_token.blank?
      status = "4041"
    else
      merchant_pos = CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id IS NULL").first rescue nil
      if merchant_pos.blank?
        status = "4042"
      else
        if !account.blank? && is_a_number?(transaction_amount)
          transaction_id = DateTime.now.to_i.to_s
          response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_operation_pos/TYHHKIRE/#{account_token}/#{merchant_pos.token}/#{transaction_amount}/0/100/#{transaction_id}/null" rescue "")

          unless response.blank?
            if response.to_s == "good"
              status = transaction_id
              response_log = response.to_s
              transaction_status = true
              Log.create(transaction_type: "Crédit de compte", account_number: account, credit_amount: transaction_amount, response_log: response.to_s, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100)
            else
              error_log = response.to_s
              Log.create(transaction_type: "Crédit de compte", account_number: account, credit_amount: transaction_amount, error_log: response.to_s, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100)
            end
          else
            error_log = request.response.body
            Log.create(transaction_type: "Crédit de compte", account_number: account, credit_amount: transaction_amount, error_log: request.response.body, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100)
          end

        end
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Crédit de compte", account_number: account, credit_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100 })

    render text: status
  end

  def check_account_number(account_number)
    token = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/check2_compte/#{account_number}" rescue "")

    return token
  end

  def check_account_number_and_password

  end

  def api_sold
    account = params[:account]
    password = params[:password]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    status = "error"
    response_log = "none"
    error_log = "none"
    transaction_status = false

    merchant_pos = CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id IS NULL").first rescue nil
    if merchant_pos.blank?
      status = "error"
    else
      if !account.blank? && !password.blank?
        transaction_id = DateTime.now.to_i.to_s
        request = Typhoeus::Request.new("#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/solte_compte/#{account}/#{password}", followlocation: true, method: :get)

        request.on_complete do |response|
          if response.success?
            response = (JSON.parse(request.response.body) rescue nil)
            unless response.blank?
              if response["compte"] != blank?
                status = response["solde"].to_i.to_s
                response_log = response.to_s
                transaction_status = true
                Log.create(transaction_type: "Solde du compte", account_number: account, response_log: response.to_s, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
              else
                error_log = response.to_s
                Log.create(transaction_type: "Solde du compte", account_number: account, error_log: response.to_s, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
              end
            else
              error_log = request.response.body
              Log.create(transaction_type: "Solde du compte", account_number: account, error_log: request.response.body, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
            end
          end
        end

        request.run
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Solde du compte", account_number: account, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id })

    render text: status
  end

  def api_checkout_account
    account = params[:account]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    transaction_amount = params[:transaction_amount]
    fee = params[:fee]
    remote_ip_address = request.remote_ip
    status = "500"
    response_log = "none"
    error_log = "none"
    transaction_status = false
    otp = ""

    account_token = check_account_number(account)
    fee = cashout_fee(transaction_amount)

    if account_token.blank?
      status = '4041'
    else
      merchant_pos = CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id IS NULL").first rescue nil
      if merchant_pos.blank?
        status = "4042"
      else
        if is_a_number?(transaction_amount) && is_a_number?(fee)
          transaction_id = DateTime.now.to_i.to_s
          request = Typhoeus::Request.new("#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_out_operation_pos/12345628/#{merchant_pos.token}/#{account_token}/#{transaction_amount}/#{fee}/100/#{transaction_id}/null", followlocation: true, method: :get)

          request.on_complete do |response|
            if response.success?
              response = (request.response.body rescue nil)
              unless response.blank?
                if !response.blank?
                  status = transaction_id
                  response_log = response.to_s
                  transaction_status = true
                  otp = response
                  Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, otp: response, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100, fee: fee)
                  status = response
                else
                  error_log = response.to_s
                  Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100, fee: fee)
                end
              else
                error_log = response.to_s
                Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100, fee: fee)
              end
            end
          end

          request.run
        end
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100, fee: fee, otp: otp })

    render text: status
  end

  def cashout_fee(ta)
    fee = "error"
    fee_type = FeeType.find_by_name("Cash out")

    if fee_type.blank?
      fee = "token invalide"
    else
      fee = fee_type.fees.where("min_value <= #{ta.to_f} AND max_value >= #{ta.to_f}").first.fee_value.to_s
    end

    return fee
  end

  def transfer_fee(ta)
    fee = "error"
    fee_type = FeeType.find_by_name("Cash out [Transfert]")

    if fee_type.blank?
      fee = "token invalide"
    else
      fee = fee_type.fees.where("min_value <= #{ta.to_f} AND max_value >= #{ta.to_f}").first.fee_value.to_s
    end

    return fee
  end

  def api_validate_checkout
    pin = params[:pin]
    transaction_id = params[:transaction_id]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    status = "500"
    transaction = Log.find_by_otp(transaction_id)
    agent_token = CertifiedAgent.find_by_certified_agent_id(agent).token
    response_log = ""
    error_log = ""
    transaction_status = false

    if !pin.blank? && !transaction.blank? && !agent_token.blank?
      account_token = check_account_number(transaction.account_number)
      request = Typhoeus::Request.new("#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos/12345628/#{account_token}/#{agent_token}/#{transaction.checkout_amount}/#{transaction.fee}/#{transaction.thumb}/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}", followlocation: true, method: :get)

      request.on_complete do |response|
        if response.success?
          response = (JSON.parse(request.response.body) rescue nil)
          unless response.blank?
            if response["otpStatus"].to_s == "true"
              response_log = response.to_s
              status = "1"
              transaction_status = true
              Log.create(transaction_type: "Validation de paiement", otp: transaction_id, pin: pin, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
            else
              error_log = response.to_s
              Log.create(transaction_type: "Validation de paiement", error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
            end
          else
            error_log = response.to_s
            Log.create(transaction_type: "Validation de paiement", error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
          end
        end
      end

      request.run

       Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Validation de débit", account_number: transaction.account_number, checkout_amount: transaction.checkout_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction.transaction_id, otp: transaction.otp, pin: pin })
    end

    render text: status
  end

  def api_ascent
    transaction_amount = params[:transaction_amount]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "500"
    transaction_status = false

    merchant_pos = CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id IS NULL").first rescue nil
    if merchant_pos.blank?
      status = "4041"
    else
      private_pos = CertifiedAgent.where("sub_certified_agent_id = '#{params[:sub_agent]}' ").first rescue nil
      if private_pos.blank?
        status = "4042"
      else
        if is_a_number?(transaction_amount)
          transaction_id = DateTime.now.to_i.to_s
          response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/Remonte/78945612/#{merchant_pos.token}/#{private_pos.token}/#{transaction_amount}/0/0/#{transaction_id}/null" rescue "")

          unless response.blank?
            if response.to_s == "good"
              status = transaction_id
              response_log = response.to_s
              transaction_status = true
              Log.create(transaction_type: "Remontée de fonds", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
            else
              error_log = response.to_s
              Log.create(transaction_type: "Remontée de fonds", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
            end
          else
            error_log = response.to_s
            Log.create(transaction_type: "Remontée de fonds", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
          end
        end
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Remontée de fonds", credit_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id })

    render text: status
  end

  def api_transfer
    transaction_amount = params[:transaction_amount]
    transaction_transfer_fee = transfer_fee(transaction_amount)
    a_account_transfer = params[:a_account_token]
    b_account_transfer = params[:b_account_token]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "500"
    transaction_status = false

    if is_a_number?(transaction_amount)
      transaction_id = DateTime.now.to_i.to_s
      print "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cashtransact/85245623/#{a_account_transfer}/#{b_account_transfer}/#{transaction_amount}/#{transaction_transfer_fee}/100/#{transaction_id}"
      response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cashtransact/85245623/#{a_account_transfer}/#{b_account_transfer}/#{transaction_amount}/#{transaction_transfer_fee}/100/#{transaction_id}" rescue "")

      unless response.blank?
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          transaction_status = true
          Log.create(transaction_type: "Transfert de crédit", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, a_account_transfer: a_account_transfer, b_account_transfer: b_account_transfer, transaction_id: transaction_id, fee: transaction_transfer_fee)
        else
          error_log = response.to_s
          Log.create(transaction_type: "Transfert de crédit", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, a_account_transfer: a_account_transfer, b_account_transfer: b_account_transfer, transaction_id: transaction_id, fee: transaction_transfer_fee)
        end
      else
        error_log = response.to_s
        Log.create(transaction_type: "Transfert de crédit", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, a_account_transfer: a_account_transfer, b_account_transfer: b_account_transfer, transaction_id: transaction_id, fee: transaction_transfer_fee)
      end
    end


    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Transfert de crédit", credit_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, a_account_transfer: a_account_transfer, b_account_transfer: b_account_transfer, transaction_id: transaction_id, fee: transaction_transfer_fee.to_i })

    render text: status
  end

  def api_get_bet
    transaction_amount = params[:transaction_amount]
    game_account_token = params[:game_account_token]
    account_token = params[:account_token]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "500"
    transaction_status = false

    if is_a_number?(transaction_amount)
      transaction_id = DateTime.now.to_i.to_s
      response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/prise_paris/96325874/#{game_account_token}/#{account_token}/#{transaction_amount}/0/0/#{transaction_id}" rescue "")

      unless response.blank?
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          transaction_status = true
          Log.create(transaction_type: "Prise de paris", checkout_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        else
          error_log = response.to_s
          Log.create(transaction_type: "Prise de paris", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        end
      else
        error_log = response.to_s
        Log.create(transaction_type: "Prise de paris", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Prise de paris", checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token })

    render text: status
  end

  def api_pay_earnings
    transaction_amount = params[:transaction_amount]
    game_account_token = params[:game_account_token]
    account_token = params[:account_token]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "500"
    transaction_status = false

    if is_a_number?(transaction_amount)
      transaction_id = DateTime.now.to_i.to_s
      response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/paiement_gain/74125895/#{account_token}/#{game_account_token}/#{transaction_amount}/0/0/#{transaction_id} " rescue "")

      unless response.blank?
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          transaction_status = true
          Log.create(transaction_type: "Paiement de gains", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        else
          error_log = response.to_s
          Log.create(transaction_type: "Paiement de gains", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        end
      else
        error_log = response.to_s
        Log.create(transaction_type: "Paiement de gains", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Paiement de gains", credit_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token })

    render text: status
  end

  def api_deposit
    transaction_amount = params[:transaction_amount]
    account_token = params[:account_token]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "500"
    transaction_status = false

    if is_a_number?(transaction_amount)
      transaction_id = DateTime.now.to_i.to_s
      response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_pos/53740905/#{account_token}/#{transaction_amount}/#{transaction_id}" rescue "")

      unless response.blank?
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          transaction_status = true
          Log.create(transaction_type: "Deposit", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_token: account_token)
        else
          error_log = response.to_s
          Log.create(transaction_type: "Deposit", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_token: account_token)
        end
      else
        error_log = response.to_s
        Log.create(transaction_type: "Deposit", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_token: account_token)
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Deposit", credit_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_token: account_token })

    render text: status
  end

  def cashin_mobile_money
    transaction_amount = params[:transaction_amount]
    account = params[:account]
    fee = params[:fee]
    mobile_money_account = params[:mobile_money_account]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "500"
    transaction_status = false

    account_token = check_account_number(account)
    mobile_money_token = check_account_number(mobile_money_account)

    if !account_token.blank? && !mobile_money_token.blank?
      if is_a_number?(transaction_amount)
        transaction_id = DateTime.now.to_i.to_s
        response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_operation_momo/tertybgd/#{account_token}/#{mobile_money_token}/#{transaction_amount}/#{fee}/100/#{transaction_id}" rescue "")

        unless response.blank?
          if response.to_s == "good"
            status = transaction_id
            response_log = response.to_s
            transaction_status = true
            Log.create(transaction_type: "Cashin mobile money", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account)
          else
            error_log = response.to_s
            Log.create(transaction_type: "Cashin mobile money", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account)
          end
        else
          error_log = response.to_s
          Log.create(transaction_type: "Cashin mobile money", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account)
        end
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Cashin mobile money", credit_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account })

    render text: status
  end

  def cashout_mobile_money
    transaction_amount = params[:transaction_amount]
    account = params[:account]
    fee = params[:fee]
    mobile_money_account = params[:mobile_money_account]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "500"
    transaction_status = false

    account_token = check_account_number(account)
    mobile_money_token = check_account_number(mobile_money_account)

    if !account_token.blank? && !mobile_money_token.blank?
      if is_a_number?(transaction_amount)
        transaction_id = DateTime.now.to_i.to_s
        response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_out_operation_momo/14725836/#{account_token}/#{mobile_money_token}/#{transaction_amount}/#{fee}/100/#{transaction_id}" rescue "")

        unless response.blank?
          if response.to_s == "good"
            status = transaction_id
            response_log = response.to_s
            transaction_status = true
            Log.create(transaction_type: "Cashout mobile money", checkout_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account)
          else
            error_log = response.to_s
            Log.create(transaction_type: "Cashout mobile money", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account)
          end
        else
          error_log = response.to_s
          Log.create(transaction_type: "Cashout mobile money", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account)
        end
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Cashout mobile money", checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account })

    render text: status
  end

  def check_agent_and_sub_agent_relationship
    if CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id  = '#{params[:sub_agent]}'").blank?
      render text: "Invalid agent"
    end
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
