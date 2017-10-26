ActiveAdmin.register User do
	
	actions :all, except: [:new]
	permit_params :role, :subscription_date, :subscription_duration, :banned, :premium_tried, :free_videos_left
	
	scope :all, default: true
	scope("Free Users") {|scope| scope.member}
	scope :donor
	scope :premium
	scope :ultimate
	scope :admin 
	scope :banned
	
	filter :id
	filter :name
	filter :email
	filter :role
	filter :subscription_date
	filter :subscription_duration

	index do
		selectable_column
		column :id
		column :name
		column :email
		column :role
		column :uid
		column :subscription_date
		column :subscription_duration
		column :banned
		actions
	end

	show do
    attributes_table do
      row :id
  		row :email
  		row :name
  		row :banned
  		row :uid
  		row :token
  		row :role
   		row :created_at
  		row :subscription_date
  		row :subscription_duration
  		row :free_videos_left if user.member?
  	end
    active_admin_comments
  end

  action_item :ban, only: :show do
  	link_to 'Ban User', ban_admin_user_path(user), method: :post unless user.banned
	end

	action_item :unban, only: :show do
  	link_to 'Unban User', unban_admin_user_path(user), method: :post if user.banned
	end

	member_action :ban, method: :post do
    resource.ban!
    redirect_to admin_user_path(resource), notice: "Banned!"
  end

  member_action :unban, method: :post do
    resource.unban!
    redirect_to admin_user_path(resource), notice: "Unbanned!"
  end



end
