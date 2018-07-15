ActiveAdmin.register LiveStream do
	
  config.per_page = 10

	scope("Erroneous") {|scope| scope.where(id: (scope.drafted + scope.request_declined + scope.deleted_from_fb + scope.network_error).map(& :id))}
	controller do
    actions :all, :except => [:edit, :destroy]
  end

  index do |livestreams|
    # columns_to_exclude = ["updated_at","live_id"]
    # (LiveStream.column_names - columns_to_exclude).each do |c|
    #   column c.to_sym
    # end
    column :handle do |ls|
      raw "<a href='https://www.facebook.com/#{ls.page_id}' target='_blank'>Click To See Details</a>" if ls.target != "other"
    end

    column :target do |ls|
      ls.target.titleize
    end

    column :video_url do |ls|
      raw "<a href='https://www.facebook.com/#{ls.video_id}' target='_blank'>View Video</a>" if ls.target != "other"
    end

    column :key do |ls|
      ls.key if ls.target == "other"
    end
    
    column :post_title do |ls|
      raw "<a href='/admin/posts/#{ls.post_id}' target='_blank'>#{ls.post.title}</a>"
    end

    column :created_at do |ls|
      ls.created_at
    end

    column :reactions do |ls|
      ls.get_reactions_count
      #raw "<a class='view_description button'>View Description</a>"
    end
  end

end
