ActiveAdmin.register Template do
	scope :poll
	scope :loop_video
	permit_params :path, :needs_background, :needs_image_names, :category, :name, :active

	index do
		selectable_column
		column :id
		column :name
		column :path
		column :needs_background
		column :needs_image_names
		column :category
		actions
	end

	filter :path
	filter :needs_background
	filter :needs_image_names
	filter :created_at
	filter :name

end
