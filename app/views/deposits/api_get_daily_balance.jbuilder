if !@error_code.blank?
  json.error code: @error_code, description: @error_description
else
  if @deposit_days.blank?
    json.deposits_on_hold []
  else
    json.deposits_on_hold @deposit_days do |deposit_day|
      json.date deposit_day.at('date').content rescue nil
      json.sales_amount deposit_day.at('saleAmount').content rescue nil
      json.cancel_amount deposit_day.at('cancelAmount').content rescue nil
      json.deposits_amount deposit_day.at('paymentAmount').content rescue nil
      json.balance deposit_day.at('balance').content rescue nil
    end
  end
end
