Rails.application.routes.draw do

  get 'webhooks/create_payment'

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
  get '/donation' => 'extras#donation'
  #get '/test' => 'extras#test'
  get '/posts/:post_id' => 'users#show' 

  scope :polls do
    get '/templates' => 'polls#templates', as: "poll_templates"
    get '/:post_id/frame' => 'polls#frame', as: "frame"
    post '/:post_id/save_canvas' => 'polls#save_canvas', as: "save_canvas"
    get '/:post_id/submit' => 'polls#submit', as: "submit_poll"
  end  

  scope :loop_videos do 
    get '/templates' => 'loop_videos#templates', as: "loop_video_templates"
    get '/:post_id/submit' => 'loop_videos#submit', as: "submit_loop_video"
  end

  scope :admins do
    get '/panel' => 'admins#panel', as: "admins_panel"
    get '/dashboard' => 'admins#dashboard', as: "admins_dashboard"
    post '/stop/:post_id' => 'admins#stop_post'
    post '/start/:post_id' => 'admins#start_post'
    post '/destroy/:post_id' => 'admins#destroy_post'
    post '/cancel/:post_id' => 'admins#cancel_scheduled_post'
  end

  scope :users do
    post '/stop/:post_id' => 'users#stop_post'
    post '/cancel/:post_id' => 'users#cancel_scheduled_post'
    get '/posts' => 'users#posts', as: "myposts"
  end

  scope :payments do
    post '/create' => "payments#create",as: "create_payment"
  end

  scope :webhooks do
    post '/newPayment' => "webhooks#newPayment"
  end
  #get '/editor/createFrame'
  #get '/editor/testFrame'

  resources :polls, :except => [:edit , :show , :index , :update, :destroy]
  resources :loop_videos, :except => [:edit , :show , :index , :update, :destroy]

  get "*path" => 'extras#invalid'
end
