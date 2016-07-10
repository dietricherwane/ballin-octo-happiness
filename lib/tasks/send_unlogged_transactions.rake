namespace :logs do
  desc "Validates Eppl bets every 17 minutes"
  	task :send_unlogged_transactions => :environment do
  	  log_obj = LogController.new
      log_obj.send_unlogged_transactions
  	end
end
