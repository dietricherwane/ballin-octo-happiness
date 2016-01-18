class AccountsController < ApplicationController

  #before_filter :check_agent_and_sub_agent_relationship, only: [:api_ascent, :api_validate_checkout, :api_credit_account, :api_sold, :api_checkout_account]

  #before_filter :create_or_update_wari_sub_agent, only: [:api_checkout_account]

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

  def set_pos_operation_token(certified_agent_id, operation_type)
    @token = ""
    # Wari
    if certified_agent_id == "af478a2c47d8418a"
      case operation_type
      when "cash_in"
        @token = "9cff7473"
      when "cash_out"
        @token = "3392eecd"
      when "ascent"
        @token = "573504f7"
      end
    end
    # Qash
    if certified_agent_id == "684239a94ca63639"
      case operation_type
      when "cash_in"
        @token = "1f039cd8"
      when "cash_out"
        @token = "b87b6c80"
      when "ascent"
        @token = "2396b109"
      end
    end
    # Smart Fidelis
    if certified_agent_id == "99999999"
      @has_rib = (RestClient.get "http://pay-money.net/pos/has_rib/#{@certified_agent_id}" rescue "")
      @has_rib.to_s == "0" ? @has_rib = false : @has_rib = true

      print "*****************" + @has_rib.to_s + "*****************"

      if operation_type == "cash_in"
        if @has_rib
          @token = "5a518a5a"
        else
          @token = "6d6dde69"
        end
      end
      if operation_type == "cash_out"
        if @has_rib
          @token = "2968e7b4"
        else
          @token = "9a28edf0"
        end
      end
      if operation_type == "ascent"
        if @has_rib
          @token = "13a3fd04"
        else
          @token = "e3875eab"
        end
      end
    end
  end

  def api_credit_account
    account = params[:account]
    transaction_amount = params[:transaction_amount]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "|5000|"
    transaction_status = false

    account_token = check_account_number(account)

    if account_token.blank?
      status = "|4041|"
    else
      merchant_pos = CertifiedAgent.where("certified_agent_id = '#{agent}' AND sub_certified_agent_id IS NULL").first rescue nil
      if merchant_pos.blank?
        status = "|4042|"
      else
        if !account.blank? && is_a_number?(transaction_amount)
          transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
          set_pos_operation_token(agent, "cash_in")
          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_operation_pos/#{@token}/#{account_token}/#{merchant_pos.token}/#{(transaction_amount.to_i rescue 0) - 100}/0/100/#{transaction_id}/null"

          if agent == "af478a2c47d8418a"
            wari_fee = cashin_wari((transaction_amount.to_i rescue 0) - 100)
            @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_operation_pos/#{@token}/#{account_token}/#{merchant_pos.token}/alOWhAgC/#{(transaction_amount.to_i rescue 0) - 100}/0/#{wari_fee}/100/#{transaction_id}/null"
          end

          BombLog.create(sent_url: @url)
          response = (RestClient.get @url rescue "")

          response = (JSON.parse(response.to_s) rescue nil)

          unless response.blank?
            if response["otpPin"] != "null" && !response["otpPin"].blank?
              status = transaction_id + '|' + response["otpTransactionId"].to_s + '|' + response["otpPin"].to_s
              response_log = response.to_s
              transaction_status = true
              Log.create(transaction_type: "Crédit de compte", account_number: account, credit_amount: transaction_amount, response_log: response.to_s, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100, otp: response["otpTransactionId"].to_s, pin: response["otpPin"].to_s)
            else
              status = "|5001|"
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

def api_sf_credit_account
    account = params[:account]
    transaction_amount = params[:transaction_amount]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "|5000|"
    transaction_status = false

    account_token = check_account_number(account)

    if account_token.blank?
      status = "|4041|"
    else
      merchant_pos = CertifiedAgent.where("certified_agent_id = '#{agent}' AND sub_certified_agent_id IS NULL").first rescue nil
      if merchant_pos.blank?
        status = "|4042|"
      else
        if !account.blank? && is_a_number?(transaction_amount)
          transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)

          @certified_agent_id = agent
          set_pos_operation_token("99999999", "cash_in")

          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_operation_pos/#{@token}/#{account_token}/#{merchant_pos.token}/#{(transaction_amount.to_i rescue 0) - 100}/0/100/#{transaction_id}/null"

          BombLog.create(sent_url: @url)
          response = (RestClient.get @url rescue "")

          response = (JSON.parse(response.to_s) rescue nil)

          unless response.blank?
            if response["otpPin"] != "null" && !response["otpPin"].blank?
              status = transaction_id + '|' + response["otpTransactionId"].to_s + '|' + response["otpPin"].to_s
              response_log = response.to_s
              transaction_status = true
              Log.create(transaction_type: "Crédit de compte", account_number: account, credit_amount: transaction_amount, response_log: response.to_s, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 100, otp: response["otpTransactionId"].to_s, pin: response["otpPin"].to_s)
            else
              status = "|5001|"
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

  def cashin_wari(ta)
    fee = ""
    fee_type = FeeType.find_by_name("Cash in Wari")

    if !fee_type.blank?
      fee = fee_type.fees.where("min_value <= #{ta.to_f} AND max_value >= #{ta.to_f}").first.fee_value.to_s rescue nil
    end

    return fee
  end

  def check_account_number(account_number)
    token = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/check2_compte/#{account_number}" rescue "")
    print token

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
    status = "|5000|"
    response_log = "none"
    error_log = "none"
    transaction_status = false

    merchant_pos = CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id IS NULL").first rescue nil
    if merchant_pos.blank?
      status = "|4042|"
    else
      if !account.blank? && !password.blank?
        transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
        BombLog.create(sent_url: "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/solte_compte/#{account}/#{password}")
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
                status = "|5001|"
                error_log = response.to_s
                Log.create(transaction_type: "Solde du compte", account_number: account, error_log: response.to_s, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
              end
            else
              error_log = response.to_s
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
    status = "|5000|"
    response_log = "none"
    error_log = "none"
    transaction_status = false
    otp = ""

    account_token = check_account_number(account)
    fee = cashout_fee(transaction_amount)

    if fee.blank?
      status = '|4043|'
    else
      if account_token.blank?
        status = '|4041|'
      else
        merchant_pos = CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id IS NULL").first rescue nil
        if merchant_pos.blank?
          status = "|4042|"
        else
          if is_a_number?(transaction_amount) && is_a_number?(fee)
            transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
            set_pos_operation_token(agent, "cash_out")

            @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_out_operation_pos/#{@token}/#{merchant_pos.token}/#{account_token}/#{transaction_amount}/#{fee}/0/#{transaction_id}/null"

            BombLog.create(sent_url: @url)
            request = Typhoeus::Request.new(@url, followlocation: true, method: :get)

            request.on_complete do |response|
              if response.success?
                #response = (request.response.body rescue nil)
                response = (JSON.parse(response.body.to_s) rescue nil)
                unless response.blank?
                  #if response != "error" && response != "error, montant insuffisant"
                  if response["otpPin"] != "null" && !response["otpPin"].blank?
                    status = transaction_id + '|' + response["otpTransactionId"].to_s + '|' + response["otpPin"].to_s
                    response_log = response.to_s
                    transaction_status = true
                    otp = response
                    Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, otp: response["otpTransactionId"].to_s, pin: response["otpPin"].to_s, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 0, fee: fee)
                  else
                    status = "|5001|"
                    error_log = response.to_s
                    Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 0, fee: fee)
                  end
                else
                  error_log = response.to_s
                  Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 0, fee: fee)
                end
              end
            end

            request.run
          end
        end
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 0, fee: fee, otp: otp })

    render text: status
  end

def api_sf_checkout_account
    account = params[:account]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    transaction_amount = params[:transaction_amount]
    fee = params[:fee]
    remote_ip_address = request.remote_ip
    status = "|5000|"
    response_log = "none"
    error_log = "none"
    transaction_status = false
    otp = ""

    account_token = check_account_number(account)
    fee = cashout_fee(transaction_amount)

    if fee.blank?
      status = '|4043|'
    else
      if account_token.blank?
        status = '|4041|'
      else
        merchant_pos = CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id IS NULL").first rescue nil
        if merchant_pos.blank?
          status = "|4042|"
        else
          if is_a_number?(transaction_amount) && is_a_number?(fee)
            transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
            @certified_agent_id = agent
            set_pos_operation_token("99999999", "cash_out")

            @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_out_operation_pos/#{@token}/#{merchant_pos.token}/#{account_token}/#{transaction_amount}/#{fee}/0/#{transaction_id}/null"

            BombLog.create(sent_url: @url)
            request = Typhoeus::Request.new(@url, followlocation: true, method: :get)

            request.on_complete do |response|
              if response.success?
                #response = (request.response.body rescue nil)
                response = (JSON.parse(response.body.to_s) rescue nil)
                unless response.blank?
                  #if response != "error" && response != "error, montant insuffisant"
                  if response["otpPin"] != "null" && !response["otpPin"].blank?
                    status = transaction_id + '|' + response["otpTransactionId"].to_s + '|' + response["otpPin"].to_s
                    response_log = response.to_s
                    transaction_status = true
                    otp = response
                    Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, otp: response["otpTransactionId"].to_s, pin: response["otpPin"].to_s, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 0, fee: fee)
                  else
                    status = "|5001|"
                    error_log = response.to_s
                    Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 0, fee: fee)
                  end
                else
                  error_log = response.to_s
                  Log.create(transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 0, fee: fee)
                end
              end
            end

            request.run
          end
        end
      end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Débit du compte", account_number: account, checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, thumb: 0, fee: fee, otp: otp })

    render text: status
  end


  def cashout_fee(ta)
    fee = ""
    fee_type = FeeType.find_by_name("Cash out")

    if !fee_type.blank?
      fee = fee_type.fees.where("min_value <= #{ta.to_f} AND max_value >= #{ta.to_f}").first.fee_value.to_s rescue nil
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

  def api_validate_credit
    pin = params[:pin]
    transaction_id = params[:transaction_id]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    status = "|5000|"
    transaction = Log.find_by_otp(transaction_id)
    agent_token = CertifiedAgent.find_by_certified_agent_id(agent).token
    response_log = ""
    error_log = ""
    transaction_status = false

    if agent_token.blank?
      status = "|4042|"
    else
      if !pin.blank? && !transaction.blank?
        account_token = check_account_number(transaction.account_number)

        set_pos_operation_token(agent, "cash_in")

        @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos/#{@token}/#{account_token}/#{agent_token}/#{(transaction.credit_amount.to_i rescue 0) - 100}/0/100/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}"

        if agent == "af478a2c47d8418a"
          wari_fee = cashin_wari((transaction.credit_amount.to_i rescue 0) - 100)
          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos_wari/#{@token}/#{account_token}/#{agent_token}/alOWhAgC/#{(transaction.credit_amount.to_i rescue 0) - 100}/0/#{wari_fee}/100/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}"
        end

        BombLog.create(sent_url: @url)
        request = Typhoeus::Request.new(@url, followlocation: true, method: :get)

        request.on_complete do |response|
          if response.success?
            response = (JSON.parse(request.response.body) rescue nil)
            unless response.blank?
              if response["otpStatus"].to_s == "true"
                response_log = response.to_s
                status = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
                transaction_status = true
                Log.create(transaction_type: "Validation de crédit", otp: transaction_id, pin: pin, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
              else
                status = "|5001|"
                error_log = response.to_s
                Log.create(transaction_type: "Validation de crédit", error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
              end
            else
              error_log = response.to_s
              Log.create(transaction_type: "Validation de crédit", error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
            end
          end
        end

        request.run
      end
       Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Validation de crédit", account_number: (transaction.account_number rescue nil), credit_amount: (transaction.credit_amount rescue nil), response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: (transaction.transaction_id rescue nil), otp: (transaction.otp rescue nil), pin: pin })
    end

    render text: status
  end

def api_sf_validate_credit
    pin = params[:pin]
    transaction_id = params[:transaction_id]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    status = "|5000|"
    transaction = Log.find_by_otp(transaction_id)
    agent_token = CertifiedAgent.find_by_certified_agent_id(agent).token
    response_log = ""
    error_log = ""
    transaction_status = false

    if agent_token.blank?
      status = "|4042|"
    else
      if !pin.blank? && !transaction.blank?
        account_token = check_account_number(transaction.account_number)

        @certified_agent_id = agent

        set_pos_operation_token("99999999", "cash_in")

        print "*****************" + @has_rib.to_s + "*****************"

        if @has_rib
          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos_avec_rib/#{@token}/#{account_token}/#{agent_token}/#{transaction.credit_amount.to_i - 100}/#{transaction.fee.blank? ? 0 : transaction.fee}/100/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}"
         else
          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos_sans_rib/#{@token}/#{account_token}/#{agent_token}/#{transaction.credit_amount.to_i - 100}/#{transaction.fee.blank? ? 0 : transaction.fee}/100/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}"
        end

        BombLog.create(sent_url: @url)
        request = Typhoeus::Request.new(@url, followlocation: true, method: :get)

        request.on_complete do |response|
          if response.success?
            response = (JSON.parse(request.response.body) rescue nil)
            unless response.blank?
              if response["otpStatus"].to_s == "true"
                response_log = response.to_s
                status = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
                transaction_status = true
                Log.create(transaction_type: "Validation de crédit", otp: transaction_id, pin: pin, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
              else
                status = "|5001|"
                error_log = response.to_s
                Log.create(transaction_type: "Validation de crédit", error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
              end
            else
              error_log = response.to_s
              Log.create(transaction_type: "Validation de crédit", error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
            end
          end
        end

        request.run
      end
       Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Validation de crédit", account_number: (transaction.account_number rescue nil), credit_amount: (transaction.credit_amount rescue nil), response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: (transaction.transaction_id rescue nil), otp: (transaction.otp rescue nil), pin: pin })
    end

    render text: status
  end


  def api_validate_checkout
    pin = params[:pin]
    transaction_id = params[:transaction_id]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    status = "|5000|"
    transaction = Log.find_by_otp(transaction_id)
    agent_token = CertifiedAgent.find_by_certified_agent_id(agent).token
    response_log = ""
    error_log = ""
    transaction_status = false

    if agent_token.blank?
      status = "|4042|"
    else
      if !pin.blank? && !transaction.blank?
        account_token = check_account_number(transaction.account_number)
        set_pos_operation_token(agent, "cash_out")
        @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos/#{@token}/#{agent_token}/#{account_token}/#{transaction.checkout_amount}/#{transaction.fee}/0/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}"
=begin
        if has_rib(agent)
          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos_avec_rib/12345628/#{agent_token}/#{account_token}/#{transaction.checkout_amount}/#{transaction.fee}/0/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}"
        else
          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos_sans_rib/12345628/#{agent_token}/#{account_token}/#{transaction.checkout_amount}/#{transaction.fee}/0/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}"
        end
=end
        BombLog.create(sent_url: @url)
        request = Typhoeus::Request.new(@url, followlocation: true, method: :get)

        request.on_complete do |response|
          if response.success?
            response = (JSON.parse(request.response.body) rescue nil)
            unless response.blank?
              if response["otpStatus"].to_s == "true"
                response_log = response.to_s
                status = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
                transaction_status = true
                Log.create(transaction_type: "Validation de paiement", otp: transaction_id, pin: pin, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
              else
                status = "|5001|"
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
      end
       Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Validation de débit", account_number: (transaction.account_number rescue nil), checkout_amount: (transaction.checkout_amount rescue nil), response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: (transaction.transaction_id rescue nil), otp: (transaction.otp rescue nil), pin: pin })
    end

    render text: status
  end

  def has_rib(certified_agent_id)
    status = (RestClient.get "http://pay-money.net/pos/has_rib/#{certified_agent_id}" rescue "")
    status == 0 ? has_rib = false : has_rib = true

    return status
  end

def api_sf_validate_checkout
    pin = params[:pin]
    transaction_id = params[:transaction_id]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    status = "|5000|"
    transaction = Log.find_by_otp(transaction_id)
    agent_token = CertifiedAgent.find_by_certified_agent_id(agent).token
    response_log = ""
    error_log = ""
    transaction_status = false

    if agent_token.blank?
      status = "|4042|"
    else
      if !pin.blank? && !transaction.blank?
        account_token = check_account_number(transaction.account_number)

        @certified_agent_id = agent

        set_pos_operation_token("99999999", "cash_out")

        if @has_rib
          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos_avec_rib/#{@token}/#{agent_token}/#{account_token}/#{transaction.checkout_amount}/#{transaction.fee}/0/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}"
        else
          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/otp_active_pos_sans_rib/#{@token}/#{agent_token}/#{account_token}/#{transaction.checkout_amount}/#{transaction.fee}/0/#{transaction.transaction_id}/null/#{pin}/#{transaction.otp}"
        end

        BombLog.create(sent_url: @url)
        request = Typhoeus::Request.new(@url, followlocation: true, method: :get)

        request.on_complete do |response|
          if response.success?
            response = (JSON.parse(request.response.body) rescue nil)
            unless response.blank?
              if response["otpStatus"].to_s == "true"
                response_log = response.to_s
                status = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
                transaction_status = true
                Log.create(transaction_type: "Validation de paiement", otp: transaction_id, pin: pin, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent)
              else
                status = "|5001|"
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
      end
       Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Validation de débit", account_number: (transaction.account_number rescue nil), checkout_amount: (transaction.checkout_amount rescue nil), response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: (transaction.transaction_id rescue nil), otp: (transaction.otp rescue nil), pin: pin })
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
    status = "|5000|"
    transaction_status = false

    merchant_pos = CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id IS NULL").first rescue nil
    if merchant_pos.blank?
      status = "|4042|"
    else
      #private_pos = CertifiedAgent.where("sub_certified_agent_id = '#{params[:sub_agent]}' ").first rescue "null"
      #if private_pos.blank?
        #status = "|4041|"
      #else
        if is_a_number?(transaction_amount)
          transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
          set_pos_operation_token(agent, "ascent")

          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/Remonte/#{@token}/#{merchant_pos.token}/#{private_pos.token}/#{transaction_amount}/0/0/#{transaction_id}/null"

          if agent == "af478a2c47d8418a"
            wari_fee = cashin_wari((transaction_amount.to_i rescue 0) - 100)
            @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/Remonte/#{@token}/#{merchant_pos.token}/#{private_pos.token}/#{transaction_amount}/0/#{wari_fee}/#{transaction_id}/null"
          end

          BombLog.create(sent_url: @url)
          response = (RestClient.get @url rescue "")

          unless response.blank?
            if response.to_s == "good"
              status = transaction_id
              response_log = response.to_s
              transaction_status = true
              Log.create(transaction_type: "Remontée de fonds", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
            else
              status = "|5001|"
              error_log = response.to_s
              Log.create(transaction_type: "Remontée de fonds", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
            end
          else
            error_log = response.to_s
            Log.create(transaction_type: "Remontée de fonds", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
          end
        end
      #end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Remontée de fonds", credit_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id })

    render text: status
  end

  def api_sf_ascent
    transaction_amount = params[:transaction_amount]
    agent = params[:agent]
    sub_agent = params[:sub_agent]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "|5000|"
    transaction_status = false

    merchant_pos = CertifiedAgent.where("certified_agent_id = '#{params[:agent]}' AND sub_certified_agent_id IS NULL").first rescue nil
    if merchant_pos.blank?
      status = "|4042|"
    else
      private_pos = CertifiedAgent.where("sub_certified_agent_id = '#{params[:sub_agent]}' ").first rescue "null"
      if private_pos.blank?
        status = "|4041|"
      else
        if is_a_number?(transaction_amount)
          transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)

          @certified_agent_id = agent

          set_pos_operation_token("99999999", "ascent")

          if @has_rib
            @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/Remonte_avec_rib/#{@token}/#{merchant_pos.token}/#{private_pos.token}/#{transaction_amount}/0/0/#{transaction_id}/null"
          else
            @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/Remonte_sans_rib/#{@token}/#{merchant_pos.token}/#{private_pos.token}/#{transaction_amount}/0/0/#{transaction_id}/null"
          end

          BombLog.create(sent_url: @url)
          response = (RestClient.get @url rescue "")

          unless response.blank?
            if response.to_s == "good"
              status = transaction_id
              response_log = response.to_s
              transaction_status = true
              Log.create(transaction_type: "Remontée de fonds", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id)
            else
              status = "|5001|"
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
    status = "|5000|"
    transaction_status = false

    if is_a_number?(transaction_amount)
      transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
      @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cashtransact/85245623/#{a_account_transfer}/#{b_account_transfer}/#{transaction_amount}/#{transaction_transfer_fee}/100/#{transaction_id}"
      BombLog.create(sent_url: @url)
      response = (RestClient.get @url rescue "")

      unless response.blank?
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          transaction_status = true
          Log.create(transaction_type: "Transfert de crédit", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, a_account_transfer: a_account_transfer, b_account_transfer: b_account_transfer, transaction_id: transaction_id, fee: transaction_transfer_fee)
        else
          status = "|5001|"
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
    password = params[:password]
    account_token = params[:account_token]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "|5000|"
    transaction_status = false

    if is_a_number?(transaction_amount)
      transaction_id = params[:transaction_id]#Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
      set_game_operation_token(game_account_token)
      @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/prise_paris/#{@token}/#{game_account_token}/#{account_token}/#{transaction_amount}/0/0/#{transaction_id}/#{password}"
      BombLog.create(sent_url: @url)
      response = (RestClient.get @url rescue "")

      unless response.blank?
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          transaction_status = true
          Log.create(transaction_type: "Prise de paris", checkout_amount: transaction_amount, response_log: response_log, status: true, bet_placed: true, bet_placed_at: DateTime.now, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        else
          status = "|5001|"
          error_log = response.to_s
          Log.create(transaction_type: "Prise de paris", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        end
      else
        error_log = response.to_s
        Log.create(transaction_type: "Prise de paris", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
      end
    end

    #Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Prise de paris", checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token })

    render text: status
  end

  def set_game_operation_token(game_account_token)
    @token = ""
    # PMU PLR
    if game_account_token == "ApXTrliOp"
      @token = "1c28caab"
    end
    # LOTO
    if game_account_token == "AliXTtooY"
      @token = "95c8b9cf"
    end
    # SPORT CASH
    if game_account_token == "LhSpwtyN"
      @token = "a46fb247"
    end
    # EPPL
    if game_account_token == "uXAXMDuW"
      @token = "c33fa532"
    end
    # CM3
    if game_account_token == "McoaDIET"
      @token = "f84d880a"
    end
  end

  def api_get_bet_without_cancellation
    transaction_amount = params[:transaction_amount]
    game_account_token = params[:game_account_token]
    password = params[:password]
    account_token = params[:account_token]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "|5000|"
    transaction_status = false

    if is_a_number?(transaction_amount)
      transaction_id = params[:transaction_id]#Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
      set_game_operation_token(game_account_token)
      @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/prise_paris_first/#{@token}/#{game_account_token}/#{account_token}/#{transaction_amount}/0/0/#{transaction_id}/#{password}"
      BombLog.create(sent_url: @url)
      response = (RestClient.get @url rescue "")

      unless response.blank?
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          transaction_status = true
          Log.create(transaction_type: "Prise de paris", checkout_amount: transaction_amount, response_log: response_log, status: true, bet_placed: true, bet_placed_at: DateTime.now, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        else
          status = "|5001|"
          error_log = response.to_s
          Log.create(transaction_type: "Prise de paris", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        end
      else
        error_log = response.to_s
        Log.create(transaction_type: "Prise de paris", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
      end
    end

    #Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Prise de paris", checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token })

    render text: status
  end

  def api_validate_bet
    transaction_amount = params[:transaction_amount].to_f
    game_account_token = params[:game_account_token]
    remote_ip_address = request.remote_ip
    bets = Log.where("game_account_token = '#{game_account_token}' AND bet_validated IS NULL")
    response_log = "none"
    error_log = "none"
    status = "|5000|"
    transaction_status = false

    unless bets.blank?
      transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s[0..17]
      status = "|5001|"

      BombLog.create(sent_url: "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/valide_paris/96325874/#{game_account_token}/#{transaction_amount}/0/0/#{transaction_id}")
      response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/valide_paris/96325874/#{game_account_token}/#{transaction_amount}/0/0/#{transaction_id}" rescue "")

      unless response.blank?
        status = "|5002|"
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          ActiveRecord::Base.connection.execute("UPDATE logs SET response_log = '#{response_log}', remote_ip_address = '#{remote_ip_address}', bet_validated = TRUE, bet_validated_at = '#{DateTime.now}', paymoney_validation_id = 'transaction_id' WHERE transaction_type = 'Prise de paris' AND game_account_token = '#{game_account_token}' AND bet_validated IS NULL")
          #bets.update_attributes(transaction_type: "Validation de paris", response_log: response_log, bet_validated: true, bet_validated_at: DateTime.now, remote_ip_address: remote_ip_address)
        else
          status = "|5003|"
          error_log = response.to_s
          ActiveRecord::Base.connection.execute("UPDATE logs SET response_log = '#{response_log}', remote_ip_address = '#{remote_ip_address}', bet_validated_at = '#{DateTime.now}' WHERE transaction_type = 'Prise de paris' AND game_account_token = '#{game_account_token}' AND bet_validated IS NULL")
          #bet.update_attributes(transaction_type: "Validation de paris", bet_validated_at: DateTime.now, error_log: error_log, remote_ip_address: remote_ip_address)
        end
      #else
        #0error_log = response.to_s
        #bet.update_attributes(transaction_type: "Validation de paris", bet_validated_at: DateTime.now, error_log: error_log, remote_ip_address: remote_ip_address)
      end
    end

    #Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Validation de paris", checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token })

    render text: status
  end

  def api_payback_bet
    bet = (Log.where(bet_placed: true, bet_validated: nil, transaction_id: params[:transaction_id]).first )

    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "|5000|"
    transaction_status = false

    if !bet.blank?
      transaction_amount = bet.checkout_amount
      account_token = bet.account_token
      game_account_token = bet.game_account_token
      transaction_id = bet.transaction_id

      BombLog.create(sent_url: "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/remboursement_paris/96325874/#{game_account_token}/#{account_token}/#{transaction_amount}/0/0/#{transaction_id}")
      response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/remboursement_paris/96325874/#{game_account_token}/#{account_token}/#{transaction_amount}/0/0/#{transaction_id}" rescue "")

      unless response.blank?
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          transaction_status = true
          bet.update_attributes(transaction_type: "Remboursement de paris", response_log: response_log, bet_paid_back: true, bet_paid_back_at: DateTime.now, remote_ip_address: remote_ip_address)
        else
          status = "|5001|"
          error_log = response.to_s
          bet.update_attributes(transaction_type: "Remboursement de paris", error_log: error_log, bet_paid_back: false, bet_paid_back_at: DateTime.now, remote_ip_address: remote_ip_address)
        end
      else
        error_log = response.to_s
        bet.update_attributes(transaction_type: "Remboursement de paris", error_log: error_log, bet_paid_back: false, bet_paid_back_at: DateTime.now, remote_ip_address: remote_ip_address)
      end
    end

    #Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Remboursement de paris", checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_token: account_token })

    render text: status
  end

  def api_pay_earnings
    transaction_amount = params[:transaction_amount]
    game_account_token = params[:game_account_token]
    account_token = params[:account_token]
    transaction_id = params[:transaction_id]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "|5000|"
    transaction_status = false

    if is_a_number?(transaction_amount)
      #transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
      BombLog.create(sent_url: "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/paiement_gain/74125895/#{account_token}/#{game_account_token}/#{transaction_amount}/0/0/#{transaction_id}")
      response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/paiement_gain/74125895/#{account_token}/#{game_account_token}/#{transaction_amount}/0/0/#{transaction_id}" rescue "")

      unless response.blank?
        if response.to_s == "good"
          status = transaction_id
          response_log = response.to_s
          transaction_status = true
          Log.create(transaction_type: "Paiement de gains", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        else
          status = "|5001|"
          error_log = response.to_s
          Log.create(transaction_type: "Paiement de gains", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
        end
      else
        error_log = response.to_s
        Log.create(transaction_type: "Paiement de gains", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token)
      end
    end

    #Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Paiement de gains", credit_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, transaction_id: transaction_id, game_account_token: game_account_token, account_token: account_token })

    render text: status
  end

  def api_deposit
    transaction_amount = params[:transaction_amount]
    account_number = params[:account_number]
    remote_ip_address = request.remote_ip
    response_log = "none"
    error_log = "none"
    status = "|5000|"
    transaction_status = false

    account_token = check_account_number(account_number)

    if account_token.blank?
      status = "|4041|"
    else
      if is_a_number?(transaction_amount)
        transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
        BombLog.create(sent_url: "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_pos/53740905/#{account_token}/#{transaction_amount}/#{transaction_id}")
        response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_pos/53740905/#{account_token}/#{transaction_amount}/#{transaction_id}" rescue "")

        unless response.blank?
          if response.to_s == "good"
            status = transaction_id
            response_log = response.to_s
            transaction_status = true
            Log.create(transaction_type: "Deposit", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_token: account_token)
          else
            status = "|5001|"
            error_log = response.to_s
            Log.create(transaction_type: "Deposit", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_token: account_token)
          end
        else
          error_log = response.to_s
          Log.create(transaction_type: "Deposit", credit_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_token: account_token)
        end
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
    status = "|5000|"
    transaction_status = false

    account_token = check_account_number(account)
    mobile_money_token = check_account_number(mobile_money_account)

    if !account_token.blank? && !mobile_money_token.blank?
      if is_a_number?(transaction_amount)
        transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
        BombLog.create(sent_url: "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_operation_momo/tertybgd/#{account_token}/#{mobile_money_token}/#{transaction_amount}/#{fee}/100/#{transaction_id}")
        response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_in_operation_momo/tertybgd/#{account_token}/#{mobile_money_token}/#{transaction_amount}/#{fee}/100/#{transaction_id}" rescue "")

        unless response.blank?
          if response.to_s == "good"
            status = transaction_id
            response_log = response.to_s
            transaction_status = true
            Log.create(transaction_type: "Cashin mobile money", credit_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account)
          else
            status = "|5001|"
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
    status = "|5000|"
    transaction_status = false

    account_token = check_account_number(account)
    mobile_money_token = check_account_number(mobile_money_account)

    if !account_token.blank? && !mobile_money_token.blank?
      if is_a_number?(transaction_amount)
        transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
        BombLog.create(sent_url: "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_out_operation_momo/14725836/#{account_token}/#{mobile_money_token}/#{transaction_amount}/#{fee}/100/#{transaction_id}")
        response = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/cash_out_operation_momo/14725836/#{account_token}/#{mobile_money_token}/#{transaction_amount}/#{fee}/100/#{transaction_id}" rescue "")

        unless response.blank?
          if response.to_s == "good"
            status = transaction_id
            response_log = response.to_s
            transaction_status = true
            Log.create(transaction_type: "Cashout mobile money", checkout_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, transaction_id: transaction_id, account_number: account, mobile_money_account_number: mobile_money_account)
          else
            status = "|5001|"
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


  def create_or_update_wari_sub_agent
    status = params[:status]
    phone_number = params[:phone_number]
    wari_sub_agent_id = params[:wari_sub_agent_id]
    request_response = '0'

    # Old pos, nothing to do
    if status == '0'

    else
      # New pos, create it
      if status == '1'
        if check_wari_private_pos_existence(params[:wari_sub_agent_id])
          request = Typhoeus::Request.new("#{Parameter.first.hub_front_office_url}/api/wari/create_private_pos", params: {phone_number: params[:phone_number], wari_sub_certified_agent_id: params[:wari_sub_agent_id]}, followlocation: true, method: :get)

          request.on_complete do |response|
            if response.success?
              if response.body == '1'

              else
                render text: '|5001|'
              end
            else
              render text: '|5000|'
            end
          end

          request.run
        else
          render text: '|6001|'
        end
      else
        # Old pos, update phone number
        if status == '2'

        else
          render text: '|6000|'
        end
      end
    end
  end

  # Before creating a new private pos, we make sure it does not exist
  def check_wari_private_pos_existence(wari_pos_id)
    if CertifiedAgent.find_by_wari_sub_agent_id(wari_pos_id).blank?
      return true
    else
      return false
    end
  end

  def deposit_fee
    @amount = params[:amount]

    if @amount.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil
  	  @error_code = 5000
  	  @error_description = "La valeur entrée n'est pas numérique."
  	else
  	  fee_type = FeeType.find_by_name("Deposit")

  	  if fee_type.blank?
  	    @error_code = 5001
  	    @error_description = "Ce type de frais n'existe pas."
  	  else
  	    @fee = fee_type.fees.where("min_value <= #{@amount.to_f} AND max_value >= #{@amount.to_f}").first.fee_value.to_s rescue nil
  	    if @fee.blank?
  	      @error_code = 5002
  	      @error_description = "Le montant entré n'est pas pris en charge."
  	    end
  	  end
  	end
  end

end
