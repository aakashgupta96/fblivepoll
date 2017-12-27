class PostsController < ApplicationController
	before_action :set_post
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :check_not_poll_and_status_of_post, only: [:select_pages, :submit_pages]
  before_action :check_slots_and_concurrent_eligibility_of_user, only: [:select_pages, :submit_pages]
  before_action :check_for_eligibility_of_free_posts, only: [:select_pages, :submit_pages]

  def share_select
  	@pages = current_user.pages
  end

  def select_pages
    @pages = current_user.pages
  end

  def submit_pages
    params["page"].each do |page_id,value|
      @post.live_streams.create(page_id: page_id) if value == "on"
    end unless params["page"].nil?
    return save_and_redirect
  end

  
  def share
  	selected_pages = Array.new()
  	params["page"].each do |page_id,value|
  		selected_pages << page_id if value == "on"
  	end unless params["page"].nil?
  	if @post.share_on(selected_pages)
  	 return redirect_to "/posts/#{@post.id}", notice: "Post shared successfully"
    else
      return redirect_to "/posts/#{@post.id}", notice: "There occurred some error while sharing post."
    end
  end

  def show
    response = HTTParty.get("https://graph.facebook.com/#{@post.page_id}?fields=name,picture{url}&access_token=#{@post.user.token}")
    @url = response.parsed_response["picture"]["data"]["url"] rescue false
    @name = response.parsed_response["name"]
    return redirect_to myposts_path, notice: Constant::INVALID_OPERATION_MESSAGE if @post.nil?
  end

  def submit
  end

  protected

  def check_not_poll_and_status_of_post
    return redirect_to dashboard_path, alert: Constant::INVALID_OPERATION_MESSAGE if @post.poll?
    return redirect_to dashboard_path, alert: Constant::INVALID_OPERATION_MESSAGE unless (@post.drafted? || @post.scheduled?)
  end

  def save_and_redirect
    if @post.save
      if (@post.status != "scheduled" and @post.can_start?)
        if @post.start 
          return redirect_to submit_post_path(@post.id)
        else
          return redirect_to root_path, alert: Constant::FB_DECLINED_REQUEST_MESSAGE
        end
      end
      return redirect_to submit_post_path(@post.id) if @post.scheduled?
      return redirect_to root_path, alert: Constant::NO_SLOT_AVAILABLE_MESSAGE
    else 
      return redirect_to frame_path(@post.id), notice: 'Error occured while saving post'
    end 
  end

end