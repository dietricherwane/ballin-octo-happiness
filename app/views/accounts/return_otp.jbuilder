if @otps.blank?

else
  json.otps @otps do |otp|
    json.transaction_type otp.transaction_type rescue nil
    json.otp otp.otp rescue nil
    json.otp otp.pin rescue nil
  end
end
