class LiveStreamsController < ApplicationController
	before_action :set_live_stream
	before_action :authenticate_user!
  before_action :authorize_user_live_stream!
  
	def share_select
  	set_user_handles
  end

  def share
  	selected_pages = Array.new()
  	params["page"].each do |page_id,value|
  		selected_pages << page_id if value == "on"
  	end unless params["page"].nil?
  	if @live_stream.share_on(selected_pages)
  	 return redirect_to show_post_path(@live_stream.post.id), notice: "Post shared successfully"
    else
      return redirect_to show_post_path(@live_stream.post.id), notice: "There occurred some error while sharing post."
    end
  end

	def cancel_scheduled_live_stream
    post = @live_stream.post
    if @live_stream.scheduled?
      @live_stream.cancel_schedule
      post.reload
      ((post.destroy) && (return (redirect_to myposts_path, notice: Constant::SCHEDULE_CANCELLED_MESSAGE))) if post.live_streams.empty?
      return redirect_to show_post_path(post.id), notice: Constant::SCHEDULE_CANCELLED_MESSAGE
    else
      return redirect_to show_post_path(post.id), notice: Constant::INVALID_OPERATION_MESSAGE
    end
  end

  def stop_live_stream
    @live_stream.stop("stopped_by_user")
    return redirect_to show_post_path(@live_stream.post.id), notice: Constant::POST_STOPPED_MESSAGE
  end

	private

	def set_live_stream
		@live_stream = LiveStream.find_by_id(params[:live_stream_id])
		if @live_stream.nil?
      return redirect_to root_path, notice: Constant::PAGE_NOT_FOUND_MESSAGE
    end
	end
end