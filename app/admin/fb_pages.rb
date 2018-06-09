ActiveAdmin.register FbPage do
	
	actions :all
	permit_params :status
	
	index do
		selectable_column
		column :id
		column :name
		column :page_id
		column :image_url
		column :fan_count
		column :status
		actions
	end

	show do
    attributes_table do
      row :id
  		row :name
  		row :page_id
  		row :image_url
  		row :fan_count
  		row :status
  		row :created_at
  	end
    active_admin_comments
  end

end
