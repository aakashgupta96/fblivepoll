ActiveAdmin.register User do
	
	permit_params :role, :subscription_date, :subscription_duration, :banned
	
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
    end
    active_admin_comments
  end

end
