Rails.application.routes.draw do

  get 'url_video/new'

  get 'url_video/create'

  devise_for :editors, skip: [:registrations, :passwords]
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :moderators, skip: [:registrations, :passwords]
  devise_for :users, controllers: {registrations: "users/registrations", sessions: "users/sessions", :omniauth_callbacks => "users/omniauth_callbacks"}
  
  mount Resque::Server, :at => "/resque"

  root 'extras#home'
  get '/privacy' => 'extras#privacy'
  get '/terms' => 'extras#terms'
  get '/demo' => 'extras#demo'
  get '/pricing' => 'extras#pricing'
  get '/faqs' => 'extras#faqs'
  get '/dashboard' => 'users#dashboard', as: "dashboard"
  get '/clients' => 'extras#clients', as: "clients"
  post '/extras/ask_question' => 'extras#ask_question'

  scope :posts do
    get '/:post_id/share' => 'posts#share_select'
    post '/:post_id/share' => 'posts#share'
    get '/:post_id/submit' => 'posts#submit', as: "submit_post"
    get '/:post_id' => 'posts#show', as: "show_post"
  end

  scope :polls do
    get '/templates' => 'polls#templates', as: "poll_templates"
    get '/:post_id/frame' => 'polls#frame', as: "frame"
    post '/:post_id/save_canvas' => 'polls#save_canvas', as: "save_canvas"
  end  

  scope :loop_videos do 
    get '/templates' => 'loop_videos#templates', as: "loop_video_templates"
  end

  scope :moderators do
    get '/panel' => 'moderators#panel', as: "moderators_panel"
    get '/dashboard' => 'moderators#dashboard', as: "moderators_dashboard"
    post '/stop/:post_id' => 'moderators#stop_post'
    post '/start/:post_id' => 'moderators#start_post'
    post '/destroy/:post_id' => 'moderators#destroy_post'
    post '/cancel/:post_id' => 'moderators#cancel_scheduled_post'
  end

  scope :users do
    post '/stop/:post_id' => 'users#stop_post'
    post '/cancel/:post_id' => 'users#cancel_scheduled_post'
    get '/posts' => 'users#posts', as: "myposts"
    get '/try_premium' => 'users#try_premium'
  end

  scope :payments do
    get '/create_instamojo' => 'payments#create_instamojo_payment', as: "create_instamojo_payment"
    post '/receiveIPN' => "payments#receive_IPN", as: "receive_IPN"
    scope :paypal do
      post '/create' => "payments#paypal_create",as: "create_paypal_payment"
      get '/verify/:payment_id' => 'payments#verify_paypal_payment'
    end
  end

  scope :editors do
    get '/lives_list' => 'editors#lives_list', as: "editors_lives_list"
    get '/users_list' => 'editors#users_list', as: "editors_users_list"
    get '/edit/:post_id' => 'editors#edit_post', as: "editors_edit_post"
    patch 'update/:post_id' => 'editors#update_post'
  end

  resources :polls, :except => [:edit , :show , :index , :update, :destroy]
  resources :loop_videos, :except => [:edit , :show , :index , :update, :destroy]
  resources :url_videos, :except => [:edit , :show , :index , :update, :destroy]

  get "*path" => 'extras#invalid'
end
