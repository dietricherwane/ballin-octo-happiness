class DepositsController < ApplicationController
  before_action :ensure_login, only: [:api_get_pos_sale_balance, :api_get_daily_balance, :api_proceed_deposit, :api_sf_proceed_deposit]

  @@user_name = "ngser@lonaci"
  @@password = "lemotdepasse"
  @@notification_url = "http://154.68.45.82:1180/api/dc4741d1b1/"
  @@hub_notification_url = "http://parionsdirect.ci/test/api/cm3" # URL vers la plateforme de Moïse
  @@cm3_server_url = "http://office.cm3.work:27000"
  #@@cm3_server_url = "http://192.168.1.44:29000"

  def reset_connection_id(error_code)
    if error_code == "501"
      CmLogin.first.delete rescue nil
      @error_code = '3000'
      @error_description = "Session interrompue, veuillez réessayer."
    end
  end

  def api_get_pos_sale_balance
    @token = params[:game_token]
    @pos_id = params[:pos_id]
    @session_id = params[:session_id]
    @error_code = ''
    @error_description = ''

    if game_token_exists
      if @game_token.code == 'ff9b6970d9'
        cm3_get_session_balance
      end
      if @game_token.code == '7284cc39bb'
        ail_pmu_get_session_balance
      end
      if @game_token.code == 'b1b1cf1c75'
        ail_loto_get_session_balance
      end
      if @game_token.code == '04f50a4961'
        spc_get_session_balance
      end
    else
      @error_code = '4000'
      @error_description = "Ce jeu n'a pas été trouvé."
    end

    DepositLog.create(game_token: @game_token, pos_id: @pos_id, deposit_request: @body, deposit_response: @response_body)
  end

  def cm3_get_session_balance
    ensure_login
    if @login_error
      @error_code = '3000'
      @error_description = "La connexion n'a pas pu être établie."
    else
      @body = "<balanceRequest><connectionId>#{@connection_id}</connectionId><sessionId>#{@session_id}</sessionId></balanceRequest>"

      send_request(@body, "#{@@cm3_server_url}/getSessionBalance")
      error_code = (@request_result.xpath('//return').at('error').content rescue nil)
      if error_code.blank? && @error != true
        @number_of_sales = (@request_result.xpath('//balance').at('nbSales').content rescue nil)
        @sales_amount = (@request_result.xpath('//balance').at('saleAmount').content rescue nil)
        @number_of_cancels = (@request_result.xpath('//balance').at('nbCancels').content rescue nil)
        @cancels_amount = (@request_result.xpath('//balance').at('cancelAmount').content rescue nil)
        @number_of_deposits = (@request_result.xpath('//balance').at('nbPayments').content rescue nil)
        @deposits_amount = (@request_result.xpath('//balance').at('paymentAmount').content rescue nil)
      else
        @error_code = '3001'
        @error_description = "La balance n'a pas pu être récupérée."

        reset_connection_id(error_code)
      end
    end
  end

  def ail_pmu_get_session_balance
    @body = ""

    send_request(@body, "")
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.blank? && @error != true

    else
      @error_code = '3001'
      @error_description = "La session n'a pas pu être récupérée."
    end
  end

  def ail_loto_get_session_balance
    @body = ""

    send_request(@body, "")
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.blank? && @error != true

    else
      @error_code = '3001'
      @error_description = "La session n'a pas pu être récupérée."
    end
  end

  def spc_get_session_balance
    @body = ""

    send_request(@body, "")
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.blank? && @error != true

    else
      @error_code = '3001'
      @error_description = "La session n'a pas pu être récupérée."
    end
  end

  def api_get_daily_balance
    @token = params[:game_token]
    @pos_id = params[:pos_id]
    @error_code = ''
    @error_description = ''

    if game_token_exists
      if @game_token.code == 'ff9b6970d9'
        cm3_get_daily_balance
      end
      if @game_token.code == '7284cc39bb'
        ail_pmu_get_daily_balance
      end
      if @game_token.code == 'b1b1cf1c75'
        ail_loto_get_daily_balance
      end
      if @game_token.code == '04f50a4961'
        spc_get_daily_balance
      end
    else
      @error_code = '4000'
      @error_description = "Ce jeu n'a pas été trouvé."
    end

    DepositLog.create(game_token: @game_token, pos_id: @pos_id, deposit_request: @body, deposit_response: @response_body)
  end

  def cm3_get_daily_balance
    if @login_error
      @error_code = '3000'
      @error_description = "La connexion n'a pas pu être établie."
    else
      @body = "<vendorBalanceRequest><connectionId>#{@connection_id}</connectionId><vendorId>#{@pos_id}</vendorId></vendorBalanceRequest>"

      send_request(@body, "#{@@cm3_server_url}/getVendorBalance")
      error_code = (@request_result.xpath('//return').at('error').content rescue nil)
      if error_code.blank? && @error != true
        @deposit_days = (@request_result.xpath('//vendorBalanceResponse/depositDay') rescue nil)
      else
        @error_code = '3001'
        @error_description = "La balance n'a pas pu être récupérée."

        reset_connection_id(error_code)
      end
    end
  end

  def ail_pmu_get_daily_balance
    body = ""

    send_request(body, "")
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.blank? && @error != true

    else
      @error_code = '3001'
      @error_description = "La balance n'a pas pu être récupérée."
    end
  end

  def ail_loto_get_daily_balance
    body = ""

    send_request(body, "")
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.blank? && @error != true

    else
      @error_code = '3001'
      @error_description = "La balance n'a pas pu être récupérée."
    end
  end

  def spc_get_daily_balance
    body = ""

    send_request(body, "")
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.blank? && @error != true

    else
      @error_code = '3001'
      @error_description = "La balance n'a pas pu être récupérée."
    end
  end

  def api_proceed_deposit
    @token = params[:game_token]
    @pos_id = params[:pos_id]
    @agent = params[:agent]
    @sub_agent = params[:sub_agent]
    @paymoney_account_number = params[:paymoney_account_number]
    @transaction_amount = params[:amount]
    @date = @date = params[:date] #(Date.today - 1).strftime("%Y-%m-%d")
    @error_code = ''
    @error_description = ''

    if game_token_exists
      if @game_token.code == 'ff9b6970d9'
        cm3_proceed_deposit
      end
      if @game_token.code == '7284cc39bb'
        ail_pmu_proceed_deposit
      end
      if @game_token.code == 'b1b1cf1c75'
        ail_loto_proceed_deposit
      end
      if @game_token.code == '04f50a4961'
        spc_proceed_deposit
      end
    else
      @error_code = '4000'
      @error_description = "Ce jeu n'a pas été trouvé."
    end
  end

  def api_sf_proceed_deposit
    @token = params[:game_token]
    @pos_id = params[:pos_id]
    @agent = params[:agent]
    @origin = "99999999"
    @sub_agent = params[:sub_agent]
    @paymoney_account_number = params[:paymoney_account_number]
    @transaction_amount = params[:amount]
    @date = params[:date]#(Date.today - 1).strftime("%Y-%m-%d")
    @error_code = ''
    @error_description = ''

    if game_token_exists
      if @game_token.code == 'ff9b6970d9'
        cm3_proceed_deposit
      end
      if @game_token.code == '7284cc39bb'
        ail_pmu_proceed_deposit
      end
      if @game_token.code == 'b1b1cf1c75'
        ail_loto_proceed_deposit
      end
      if @game_token.code == '04f50a4961'
        spc_proceed_deposit
      end
    else
      @error_code = '4000'
      @error_description = "Ce jeu n'a pas été trouvé."
    end
  end

  def cm3_proceed_deposit
    body = "<vendorDepositRequest><connectionId>#{@connection_id}</connectionId><deposit><vendorId>#{@pos_id}</vendorId><date>#{@date}</date><amount>#{@transaction_amount}</amount></deposit></vendorDepositRequest>"

    @deposit = Deposit.create(game_token: @token, pos_id: @pos_id, agent: @agent, sub_agent: @sub_agent, paymoney_account: @paymoney_account_number, deposit_day: @date, deposit_amount: @transaction_amount, deposit_request: body, transaction_id: Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s)

    send_request(body, "#{@@cm3_server_url}/depositVendorCash")
    @deposit.update_attributes(deposit_response: @response_body)
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.to_s == "0" && @error != true
      @deposit.update_attributes(deposit_made: true)
      cm3_paymoney_deposit
    else
      @error_code = (@request_result.xpath('//return').at('error').content rescue nil)
      @error_description = (@request_result.xpath('//message').at('error').content rescue nil)

      reset_connection_id(error_code)
    end
  end

  def cm3_paymoney_deposit
    @paymoney_account_token = check_account_number(@paymoney_account_number)

    paymoney_wallet_url = (Parameters.first.paymoney_wallet_url rescue "")
    @transaction_amount = @transaction_amount
    status = false

    if @transaction_amount == 0
     @error_code = '5000'
     @error_description = "Le montant de transaction n'est pas valide."
    else
      #if @paymoney_account_token.blank?
        #@error_code = '5001'
        #@error_description = "Ce compte paymoney n'existe pas."
      #else
        #@url = "api_ascent"

        #if @agent == "99999999"
          #@url = "api_sf_ascent"
        #end

        if @origin == "99999999"
          if !api_sf_ascent.include?("|")
            @deposit.update_attributes(paymoney_request: @url, paymoney_response: @status)
            status = true
          else
            @error_code = '4002'
            @error_description = 'Paymoney-Erreur de paiement.'
            @deposit.update_attributes(paymoney_request: @url, paymoney_response: CertifiedAgent.where("certified_agent_id = '#{@agent}' AND sub_certified_agent_id IS NULL").first.inspect)
          end
        else
          if !api_ascent.include?("|")
            @deposit.update_attributes(paymoney_request: @url, paymoney_response: @status)
            status = true
          else
            @error_code = '4001'
            @error_description = 'Paymoney-Erreur de paiement.'
            @deposit.update_attributes(paymoney_request: @url, paymoney_response: @status)
          end
        end

      #end
    end

    return status
  end

  def ail_pmu_proceed_deposit

    body = ""

    #@deposit = Deposit.create(game_token: @token, pos_id: @pos_id, agent: @agent, sub_agent: @sub_agent, paymoney_account: @paymoney_account_number, deposit_day: @date, deposit_amount: @transaction_amount, deposit_request: body, transaction_id: Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s)

    send_request(body, "")
    #@deposit.update_attributes(deposit_response: @response_body)
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.to_s == "0" && @error != true
      #@deposit.update_attributes(deposit_made: true)
      #cm3_paymoney_deposit
    else
      @error_code = (@request_result.xpath('//return').at('error').content rescue nil)
      @error_description = (@request_result.xpath('//message').at('error').content rescue nil)
    end
  end

  def ail_loto_proceed_deposit
    body = ""

    #@deposit = Deposit.create(game_token: @token, pos_id: @pos_id, agent: @agent, sub_agent: @sub_agent, paymoney_account: @paymoney_account_number, deposit_day: @date, deposit_amount: @transaction_amount, deposit_request: body, transaction_id: Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s)

    send_request(body, "")
    #@deposit.update_attributes(deposit_response: @response_body)
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.to_s == "0" && @error != true
      #@deposit.update_attributes(deposit_made: true)
      #cm3_paymoney_deposit
    else
      @error_code = (@request_result.xpath('//return').at('error').content rescue nil)
      @error_description = (@request_result.xpath('//message').at('error').content rescue nil)
    end
  end

  def spc_proceed_deposit
    body = ""

    #@deposit = Deposit.create(game_token: @token, pos_id: @pos_id, agent: @agent, sub_agent: @sub_agent, paymoney_account: @paymoney_account_number, deposit_day: @date, deposit_amount: @transaction_amount, deposit_request: body, transaction_id: Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s)

    send_request(body, "")
    #@deposit.update_attributes(deposit_response: @response_body)
    error_code = (@request_result.xpath('//return').at('error').content rescue nil)
    if error_code.to_s == "0" && @error != true
      #@deposit.update_attributes(deposit_made: true)
      #cm3_paymoney_deposit
    else
      @error_code = (@request_result.xpath('//return').at('error').content rescue nil)
      @error_description = (@request_result.xpath('//message').at('error').content rescue nil)
    end
  end

  def api_ascent
    transaction_amount = @transaction_amount
    agent = @agent
    sub_agent = @sub_agent
    remote_ip_address = ""#request.remote_ip
    response_log = "none"
    error_log = "none"
    @status = "|5000|"
    transaction_status = false
    @fee = "0"

    merchant_pos = CertifiedAgent.where("certified_agent_id = '#{agent}' AND sub_certified_agent_id IS NULL").first rescue nil
    if merchant_pos.blank?
      @status = "|4042|"
    else
      #private_pos = CertifiedAgent.where("sub_certified_agent_id = '#{params[:sub_agent]}' ").first rescue "null"
      #if private_pos.blank?
        #status = "|4041|"
      #else
        if is_a_number?(transaction_amount)
          transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)
          set_pos_operation_token(agent, "ascent")

          @fee = check_deposit_fee((transaction_amount.to_i rescue 0))

          @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/Remonte/#{@token}/#{merchant_pos.token}/#{@paymoney_account_token.blank? ? 'DNLiVHcI' : @paymoney_account_token}/#{transaction_amount}/#{@fee}/100/#{transaction_id}/null"

          if agent == "af478a2c47d8418a"
            @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/Remonte/#{@token}/#{merchant_pos.token}/#{@paymoney_account_token.blank? ? 'DNLiVHcI' : @paymoney_account_token}/#{transaction_amount}/#{@fee}/100/#{transaction_id}/null"
          end

          BombLog.create(sent_url: @url)
          response = (RestClient.get @url rescue "")

          unless response.blank?
            if response.to_s == "good"
              @status = transaction_id
              response_log = response.to_s
              transaction_status = true
              Log.create(transaction_type: "Remontée de fonds", checkout_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, fee: @fee)
            else
              @status = "|5001|"
              error_log = response.to_s
              Log.create(transaction_type: "Remontée de fonds", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, fee: @fee)
            end
          else
            error_log = response.to_s
            Log.create(transaction_type: "Remontée de fonds", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, fee: @fee)
          end
        end
      #end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Remontée de fonds", checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, fee: @fee })

    return @status
  end

  def api_sf_ascent
    transaction_amount = @transaction_amount
    agent = @agent
    sub_agent = @sub_agent
    remote_ip_address = ""
    response_log = "none"
    error_log = "none"
    @status = "|5000|"
    transaction_status = false
    @fee = "0"

    merchant_pos = CertifiedAgent.where("certified_agent_id = '#{@agent}' AND sub_certified_agent_id IS NULL").first rescue nil
    if merchant_pos.blank?
      @status = "|4042|"
    else
      #private_pos = CertifiedAgent.where("sub_certified_agent_id = '#{params[:sub_agent]}' ").first rescue "null"
      #if private_pos.blank?
        #status = "|4041|"
      #else
        if is_a_number?(transaction_amount)
          transaction_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join)

          @certified_agent_id = agent

          set_pos_operation_token("99999999", "ascent")

          @fee = check_deposit_fee((transaction_amount.to_i rescue 0))

          if has_rib(@agent)
            @token = "13a3fd04"
            @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/Remonte_avec_rib/#{@token}/#{merchant_pos.token}/#{@paymoney_account_token.blank? ? 'DNLiVHcI' : @paymoney_account_token}/#{transaction_amount}/#{@fee}/100/#{transaction_id}/null"
          else
            @token = "e3875eab"
            @url = "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/Remonte_sans_rib/#{@token}/#{merchant_pos.token}/#{@paymoney_account_token.blank? ? 'DNLiVHcI' : @paymoney_account_token}/#{transaction_amount}/#{@fee}/100/#{transaction_id}/null"
          end

          BombLog.create(sent_url: @url)
          response = (RestClient.get @url rescue "")

          unless response.blank?
            if response.to_s == "good"
              @status = transaction_id
              response_log = response.to_s
              transaction_status = true
              Log.create(transaction_type: "Remontée de fonds", checkout_amount: transaction_amount, response_log: response_log, status: true, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, fee: @fee)
            else
              @status = "|5001|"
              error_log = response.to_s
              Log.create(transaction_type: "Remontée de fonds", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, fee: @fee)
            end
          else
            error_log = response.to_s
            Log.create(transaction_type: "Remontée de fonds", checkout_amount: transaction_amount, error_log: error_log, status: false, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, fee: @fee)
          end
        end
      #end
    end

    Typhoeus.get("#{Parameter.first.hub_front_office_url}/api/367419f5968800cd/paymoney_wallet/store_log", params: { transaction_type: "Remontée de fonds", checkout_amount: transaction_amount, response_log: response_log, error_log: error_log, status: transaction_status, remote_ip_address: remote_ip_address, agent: agent, sub_agent: sub_agent, transaction_id: transaction_id, fee: @fee })

    return @status
  end

  def game_token_exists
    @game_token = GameToken.find_by_code(@token)
    status = true

    if @game_token.blank?
      status = false
    end

    return status
  end

  def send_request(body, url)
    @request_result = nil
    @response_code = nil

    request = Typhoeus::Request.new(url, body: body, followlocation: true, method: :get, headers: {'Content-Type'=> "text/xml"})

    request.on_complete do |response|
      if response.success?
        @response_body = response.body
        @request_result = (Nokogiri::XML(@response_body) rescue nil)
      else
        @error = true
        @response_code = response.code rescue nil
      end
    end

    request.run
  end

  def ensure_login
    @connection_id = CmLogin.first.connection_id rescue nil
    if @connection_id.blank?
      body = %Q[<?xml version='1.0' encoding='UTF-8'?>
                <loginRequest>
                  <username>#{@@user_name}</username>
                  <password>#{@@password}</password>
                  <notificationUrl>#{@@notification_url}</notificationUrl>
                </loginRequest>]
      send_request(body, "#{@@cm3_server_url}/login")

      error_code = (@request_result.xpath('//return').at('error').content rescue nil)

      if error_code.blank? && @error != true
        @connection_id = (@request_result.xpath('//loginResponse').at('connectionId').content  rescue nil)
        CmLogin.create(connection_id: @connection_id)
        CmLog.create(operation: "Login", connection_id: @connection_id, login_request: body, login_response: @response_body)
      else
        @login_error = true
        CmLogin.first.delete rescue nil
        CmLog.create(login_error_code: error_code, login_error_description: (@request_result.xpath('//return').at('message').content rescue nil), login_request: body, login_response: @response_body, login_error_code: @response_code)
      end
    end
  end

  def check_account_number(account_number)
    token = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/check2_compte/#{account_number}" rescue "")

    if token == "null"
      token = ""
    end

    return token
  end
end
