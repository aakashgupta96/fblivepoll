Rails.application.routes.draw do
  
  devise_for :admins, skip: [:registrations, :passwords]
  devise_for :users, controllers: {registrations: "users/registrations", sessions: "users/sessions", :omniauth_callbacks => "users/omniauth_callbacks"}
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  # You can have the root of your site routed with "root"
  mount Resque::Server, :at => "/resque"

  root 'extras#home'
  get '/privacy' => 'extras#privacy'
  get '/terms' => 'extras#terms'
  get '/demo' => 'extras#demo'
  get '/test' => 'extras#test'
  
  get '/polls/:post_id/frame' => 'polls#frame', as: "frame"
  post '/polls/:post_id/save_canvas' => 'polls#save_canvas', as: "save_canvas"
  get '/polls/:post_id/submit' => 'polls#submit', as: "submit_poll"
  
  get '/loop_videos/:post_id/submit' => 'loop_videos#submit', as: "submit_loop_video"

  get '/admins/dashboard' => 'admins#dashboard'
  post '/admins/stop/:post_id' => 'admins#stop_post'
  
  post '/users/stop/:post_id' => 'users#stop_post'
  post '/users/cancel/:post_id' => 'users#cancel_scheduled_post'
  get '/users/posts' => 'users#posts', as: "myposts"
  #get '/editor/createFrame'
  #get '/editor/testFrame'
  


  resources :polls, :except => [:edit , :show , :index , :update, :destroy]
  resources :loop_videos, :except => [:edit , :show , :index , :update, :destroy]





  get "*path" => 'extras#invalid'
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

  #get "*path" => redirect('/')
  

end
