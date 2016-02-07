class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

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

  # Check if the parameter is not a number
  def is_a_number?(n)
  	n.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  end

  def check_deposit_fee(ta)
    fee = ""
    fee_type = FeeType.find_by_name("Deposit")

    if !fee_type.blank?
      fee = fee_type.fees.where("min_value <= #{ta.to_f} AND max_value >= #{ta.to_f}").first.fee_value.to_s rescue nil
    end

    return fee
  end

end
