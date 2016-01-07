if !@error_code.blank?
  json.error code: @error_code, description: @error_description
else
  json.deposit do
    json.date @date
    json.amount @transaction_amount
    json.transaction_id @transaction_id
  end
end
