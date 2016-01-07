if !@error_code.blank?
  json.error code: @error_code, description: @error_description
else
  json.balance do
    json.pos_id @pos_id
    json.number_of_sales @number_of_sales
    json.sales_amount @sales_amount
    json.number_of_cancels @number_of_cancels
    json.cancels_amount @cancels_amount
    json.number_of_payments @number_of_payments
    json.payments_amount @payments_amount
  end
end
