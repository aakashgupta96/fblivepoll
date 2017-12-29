class PostsController < ApplicationController
	before_action :set_post
  before_action :authenticate_user!
  before_action :authorize_user_post!
  before_action :check_not_poll_and_status_of_post, only: [:select_pages, :submit_pages]
  before_action :check_slots_and_concurrent_eligibility_of_user, only: [:select_pages, :submit_pages]
  before_action :check_for_eligibility_of_free_posts, only: [:select_pages, :submit_pages]

  def select_pages
    @pages = current_user.pages
  end

  def submit_pages
    return redirect_to show_post_path(@post.id), notice: "Post details have already been submitted. Modifications are not allowed." unless @post.live_streams.empty?
    params["page"].each do |page_id,value|
      @post.live_streams.create(page_id: page_id, status: @post.status) if value == "on"
    end unless params["page"].nil?
    return save_and_redirect
  end

  def cancel_scheduled_post
    if @post.scheduled?
      @post.cancel_scheduled
      return redirect_to myposts_path, notice: Constant::SCHEDULE_CANCELLED_MESSAGE
    else
      return redirect_to myposts_path, notice: Constant::INVALID_OPERATION_MESSAGE
    end
  end

  def stop_post
    @post.stop("stopped_by_user")
    return redirect_to show_post_path(@post.id), notice: Constant::POST_STOPPED_MESSAGE
  end

  def show
    @pages = @post.live_streams.get_details unless Constant::RTMP_TEMPLATE_IDS.include?(@post.template.id)
    return redirect_to myposts_path, notice: Constant::INVALID_OPERATION_MESSAGE if @post.nil?
  end

  def submit
  end

  protected

  def check_not_poll_and_status_of_post
    return redirect_to dashboard_path, alert: Constant::INVALID_OPERATION_MESSAGE if (@post.poll? || @post.template == Template.find_by_name("Hybrid Video")) #Hybrid template is also not allowed
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