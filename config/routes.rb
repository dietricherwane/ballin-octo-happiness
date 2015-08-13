Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'errors#routing'

  get '/api/1314a3dfb72826290bbc99c71b510d2b/account/create/:msisdn' => 'accounts#api_create'
  get '/api/1314a3dfb72826290bbc99c71b510d2b/:agent/:sub_agent/account/credit/:account/:transaction_amount' => 'accounts#api_credit_account', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}
  get '/api/1314a3dfb72826290bbc99c71b510d2b/:agent/:sub_agent/account/checkout/:account/:password/:transaction_amount' => 'accounts#api_checkout_account', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}
  get '/api/1314a3dfb72826290bbc99c71b510d2b/:agent/:sub_agent/account/sold/:account/:password' => 'accounts#api_sold'
  get '/api/1314a3dfb72826290bbc99c71b510d2b/:agent/:sub_agent/account/checkout_validate/:transaction_id/:pin' => 'accounts#api_validate_checkout'

  get '/api/86d138798bc43ed59e5207c68e864564/:certified_agent_id' => 'certified_agents#create'

  get '/api/1314a3dfb72826290bbc99c71b510d2b/fee/:fee_type_token/:transaction_amount' => 'fees#cashout', :constraints => {:transaction_amount => /(\d+(.\d+)?)/}

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
