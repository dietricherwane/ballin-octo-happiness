class DepositsController < ApplicationController
  before_action :ensure_login, only: [:api_get_pos_sale_balance, :api_get_daily_balance, :api_proceed_deposit, :api_sf_proceed_deposit]

  @@user_name = "ngser@lonaci"
  @@password = "lemotdepasse"
  @@notification_url = "https://142.11.15.18:11111"
  #@@url = "http://192.168.1.44:29000"
  @@url = "http://office.cm3.work:27000"

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

      send_request(@body, "#{@@url}/getSessionBalance")
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

      send_request(@body, "#{@@url}/getVendorBalance")
      error_code = (@request_result.xpath('//return').at('error').content rescue nil)
      if error_code.blank? && @error != true
        @deposit_days = (@request_result.xpath('//vendorBalanceResponse/depositDay') rescue nil)
      else
        @error_code = '3001'
        @error_description = "La balance n'a pas pu être récupérée."
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
    @date = params[:date]
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
    @agent = "99999999"
    @sub_agent = params[:sub_agent]
    @paymoney_account_number = params[:paymoney_account_number]
    @transaction_amount = params[:amount]
    @date = params[:date]
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
    ensure_login
    if @login_error
      @error_code = '3000'
      @error_description = "La connexion n'a pas pu être établie."
    else
      body = "<vendorDepositRequest><connectionId>#{@connection_id}</connectionId><deposit><vendorId>#{@pos_id}</vendorId><date>#{@date}</date><amount>#{@transaction_amount}</amount></deposit></vendorDepositRequest>"

      @deposit = Deposit.create(game_token: @token, pos_id: @pos_id, agent: @agent, sub_agent: @sub_agent, paymoney_account: @paymoney_account_number, deposit_day: @date, deposit_amount: @transaction_amount, deposit_request: body, transaction_id: Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s)

      send_request(body, "#{@@url}/depositVendorCash")
      @deposit.update_attributes(deposit_response: @response_body)
      error_code = (@request_result.xpath('//return').at('error').content rescue nil)
      if error_code.to_s == "0" && @error != true
        @deposit.update_attributes(deposit_made: true)
        cm3_paymoney_deposit
      else
        @error_code = (@request_result.xpath('//return').at('error').content rescue nil)
        @error_description = (@request_result.xpath('//message').at('error').content rescue nil)
      end
    end
  end

  def cm3_paymoney_deposit
    paymoney_account_token = check_account_number(@paymoney_account_number)

    paymoney_wallet_url = (Parameters.first.paymoney_wallet_url rescue "")
    @transaction_amount = @transaction_amount
    status = false

    if @transaction_amount == 0
     @error_code = '5000'
     @error_description = "Le montant de transaction n'est pas valide."
    else
      if paymoney_account_token.blank?
        @error_code = '5001'
        @error_description = "Ce compte paymoney n'existe pas."
      else
        @url = "#{paymoney_wallet_url}/api/1314a3dfb726290bbc99c71b510d2b/#{@agent}/#{@sub_agent}/account/ascent/#{@transaction_amount}"

        if @agent == "99999999"
          @url = "#{paymoney_wallet_url}/api/c067d6dc6a578a789e8fdb4c4556c239/#{@agent}/#{@sub_agent}/account/ascent/#{@transaction_amount}"
        end

        request = Typhoeus::Request.new(@url, followlocation: true, method: :get)

        request.on_complete do |response|
          if response.success?
            response_body = response.body

            if !response_body.include?("|")
              @deposit.update_attributes(paymoney_transaction_id: response_body, paymoney_request: @url, paymoney_response: response_body)
              status = true
            else
              @error_code = '4001'
              @error_description = 'Paymoney-Erreur de paiement.'
              @deposit.update_attributes(paymoney_request: @url, paymoney_response: response_body)
            end
          else
            @error_code = '4000'
            @error_description = "Le serveur de paiement n'est pas disponible."
            @deposit.update_attributes(paymoney_request: @url, paymoney_response: response_body)
          end
        end

        request.run
      end
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
    body = %Q[<loginRequest>
                <username>#{@@user_name}</username>
                <password>#{@@password}</password>
                <notificationUrl>#{@@notification_url}</notificationUrl>
              </loginRequest>]

    send_request(body, "#{@@url}/login")

    error_code = (@request_result.xpath('//return').at('error').content rescue nil)

    if error_code.blank? && @error != true
      @connection_id = (@request_result.xpath('//loginResponse').at('connectionId').content  rescue nil)
    else
      @login_error = true
    end
  end

  def check_account_number(account_number)
    token = (RestClient.get "#{Parameter.first.paymoney_wallet_url}/PAYMONEY_WALLET/rest/check2_compte/#{account_number}" rescue "")

    return token
  end
end
