Rails.application.routes.draw do

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'errors#routing'

  #get '/api/1314a3dfb72826290bbc99c71b510d2b/account/create/:msisdn' => 'accounts#api_create'
  get '/api/1314a3dfb72826290bbc99c71b510d2b/:agent/:sub_agent/account/credit/:account/:transaction_amount' => 'accounts#api_credit_account', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Wari
  get '/api/b1a02cc2e4a70953aa49d93/:agent/:wari_sub_agent_id/:phone_number/:status/account/credit/:account/:transaction_amount' => 'accounts#api_credit_account', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  get '/api/1314a3dfb72826290bbc99c71b510d2b/:agent/:sub_agent/account/checkout/:account/:transaction_amount' => 'accounts#api_checkout_account', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Wari
  get '/api/c99c71b510d2b/:agent/:wari_sub_agent_id/:phone_number/:status/account/checkout/:account/:transaction_amount' => 'accounts#api_checkout_account', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  get '/api/1314a3dfb72826290bbc99c71b510d2b/:agent/:sub_agent/account/sold/:account/:password' => 'accounts#api_sold'
  get '/api/1314a3dfb72826290bbc99c71b510d2b/:agent/:sub_agent/account/checkout_validate/:transaction_id/:pin' => 'accounts#api_validate_checkout'

  get '/api/1314a3dfb72826290bbc99/:agent/:sub_agent/account/credit_validate/:transaction_id/:pin' => 'accounts#api_validate_credit'

  get '/api/86d138798bc43ed59e5207c68e864564/:certified_agent_id/:account_number/:token' => 'certified_agents#create'
  get '/api/86d138798bc43ed59e5207c68e864564/:certified_agent_id/:sub_certified_agent_id/:account_number/:token' => 'certified_agents#create'

  get '/api/86d138798bc43ed59e5207c68e864564/:certified_agent_id/:sub_certified_agent_id/:wari_sub_agent_id/:account_number/:token' => 'certified_agents#create'

  get '/api/1314a3dfb72826290bbc99c71b510d2b/fee/:fee_type_token/:transaction_amount' => 'fees#cashout', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Ascent
  get '/api/1314a3dfb726290bbc99c71b510d2b/:agent/:sub_agent/account/ascent/:transaction_amount' => 'accounts#api_ascent', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Take bet
  get '/api/86d138798bc43ed59e5207c684564/bet/get/:game_account_token/:account_token/:password/:transaction_amount' => 'accounts#api_get_bet', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Validate a bet
  get '/api/06331525768e6a95680c8bb0dcf55/bet/validate/:transaction_id' => 'accounts#api_validate_bet'

  # Cancel a bet
  get '/api/35959d477b5ffc06dc673befbe5b4/bet/payback/:transaction_id' => 'accounts#api_payback_bet'

  # Pay earnings
  get '/api/86d1798bc43ed59e5207c68e864564/earnings/pay/:game_account_token/:account_token/:transaction_amount' => 'accounts#api_pay_earnings', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Deposit
  get '/api/86d13843ed59e5207c68e864564/deposit/:account_number/:transaction_amount' => 'accounts#api_deposit', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Transfert
  get '/api/86d138798bc43ed59e5207c68e864/account/transfer/:a_account_token/:b_account_token/:transaction_amount' => 'accounts#api_transfer', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Cashin from mobile money
  get '/api/86d138798bc43ed59e5207c664/mobile_money/cashin/:mobile_money_account/:account/:transaction_amount/:fee' => 'accounts#cashin_mobile_money', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Cashout from mobile money
  get '/api/88bc43ed59e5207c68e864564/mobile_money/cashout/:mobile_money_account/:account/:transaction_amount/:fee' => 'accounts#cashout_mobile_money', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

  # Displaying logs
  get '/logs/derniere_requete_vers_la_bombe' => 'bomb_logs#last_request'
  get '/logs/derniere_reponse_de_la_bombe' => 'bomb_logs#last_return'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  get '*rogue_url', :to => 'errors#routing'
  post '*rogue_url', :to => 'errors#routing'
end
