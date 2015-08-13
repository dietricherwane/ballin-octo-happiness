class FeesController < ApplicationController

  def cashout
    fee = "error"
    fee_type = FeeType.find_by_token(params[:fee_type_token])

    if fee_type.blank?
      fee = "token invalide"
    else
      fee = fee_type.fees.where("min_value <= #{params[:transaction_amount].to_f} AND max_value >= #{params[:transaction_amount].to_f}").first.fee_value.to_s
    end

    render text: fee
  end

end
