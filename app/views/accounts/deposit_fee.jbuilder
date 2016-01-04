if !@error_code.blank?
  json.error code: @error_code, description: @error_description
else
  json.deposit do
    json.amount @amount
    json.fee @fee
  end
end
