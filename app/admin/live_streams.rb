ActiveAdmin.register LiveStream do
	before_filter :skip_sidebar!, :only => :index
  config.per_page = 10

	scope("Erroneous") {|scope| scope.where(id: (scope.drafted + scope.request_declined + scope.deleted_from_fb + scope.network_error).map(& :id))}
	controller do
    actions :all, :except => [:edit, :destroy]
  end

  width = 50
  margin = 5
  str = "
    <div>
      <div style='text-align: center;'>Report</div>
      <div style='display: flex;'>
        <div style='width: 100px; margin-right: #{margin}px; text-align: center;'>
          Handle Name 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          Like 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          Love 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          Haha 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          Wow 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          Sad 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          Angry 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          Comments
        </div>
      </div>
    </div>
  "
  index do |livestreams|
    # columns_to_exclude = ["updated_at","live_id"]
    # (LiveStream.column_names - columns_to_exclude).each do |c|
    #   column c.to_sym
    # end

    column :id

    column raw(str) do |ls|
      result = ls.get_reactions_count
      raw "
      <div style='display: flex;'>
        <div style='width: 100px; margin-right: #{margin}px; text-align: center;'>
          <a href='https://www.facebook.com/#{ls.page_id}' target='_blank'>#{result['from'].nil? ? "NA" : result['from']} </a>
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          #{result['like'].nil? ? "NA" : result['like']} 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          #{result['love'].nil? ? "NA" : result['love']} 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
         #{result['haha'].nil? ? "NA" : result['haha']} 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
         #{result['wow'].nil? ? "NA" : result['wow']} 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          #{result['sad'].nil? ? "NA" : result['sad']} 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          #{result['angry'].nil? ? "NA" : result['angry']} 
        </div>
        <div style='width: #{width}px; margin-right: #{margin}px; text-align: center;'>
          #{result['comments'].nil? ? "NA" : result['comments']} 
        </div>
      </div>
      "
    end

    column :target do |ls|
      ls.target.titleize.split.last
    end

    column :status do |ls|
      status_message(ls)
    end

    column :facebook_video_link do |ls|
      if ls.target == "other"
        "NA"
      else
        raw "<a href='https://www.facebook.com/#{ls.video_id}' target='_blank'>View Video</a>" 
      end
    end
    
    column :shareable_url do |ls|
      ls.post.link.url rescue "NA"
    end

    column :start_time do |ls|
      ls.post.start_time.in_time_zone(TZInfo::Timezone.get('Asia/Kolkata')).to_time
    end

    column :duration do |ls|
      "#{ls.post.duration.hour} hours #{ls.post.duration.min} minutes"
    end

    actions
    
  end

end
