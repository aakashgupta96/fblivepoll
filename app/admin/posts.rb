ActiveAdmin.register Post do

	config.per_page = 9
  actions :all, except: [:new]
	permit_params :title, :caption, :reload_browser, :duration, :live, :start_time, :status, :counter_color, :default_message, :page_id

	scope :all, default: true
	scope :poll
	scope :loop_video
  scope :url_video
	scope :queued
	scope :published
	scope :scheduled
	scope :live

	filter :created_at
	filter :template
	filter :title
	filter :caption
	filter :live
  filter :user
  filter :user_id

	show do
    attributes_table do
      row :title
  		row :caption
  		row :key
  		row :duration
  		row :user
   		row :live
  		row :category
  		row :start_time if post.scheduled?
  		row :image
  		row :video if post.loop_video?
      row :template
      row :default_message
      row :status
      row :link if post.url_video?
    end
    active_admin_comments
  end

	index as: :grid do |post|
		a href: admin_post_path(post) do
        img src: image_url(post), style: "width: 100%;"
        div post.title, style: "text-align: center; font-size: 18px;"
    end
    #link_to image_tag(post.image.url, {style: "width: 250px;"}), admin_post_path(post)
	end

  action_item :update_screenshot, only: :show do 
    link_to 'Update Screenshot', update_screenshot_admin_post_path(post), method: :post if post.poll?
  end

	action_item :stop, only: :show do
  	link_to 'Stop', stop_admin_post_path(post), method: :post if post.live
	end

	action_item :start, only: :show do
  	link_to 'Start Now', start_admin_post_path(post), method: :post unless post.live
	end

	action_item :cancel_schedule, only: :show do
  	link_to 'Cancel Schedule', cancel_schedule_admin_post_path(post), method: :post if post.scheduled?
	end

	member_action :update_screenshot, method: :post do 
    resource.take_screenshot_of_frame
    redirect_to admin_post_path(resource)
  end

  member_action :stop, method: :post do
    resource.stop
    redirect_to admin_post_path(resource), notice: "Stopped!"
  end

  member_action :start, method: :post do
    resource.start
    redirect_to admin_post_path(resource), notice: "Pushed To Queue!"
  end

  member_action :cancel_schedule, method: :post do
    resource.schedule_cancelled!
    redirect_to admin_post_path(resource), notice: "Schedule Cancelled!"
  end

  

end