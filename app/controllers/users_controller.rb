class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, except: [:posts, :dashboard, :try_premium]
  before_action :authorize_user!, except: [:posts, :dashboard, :try_premium]
  
  def posts
  	@posts = current_user.posts.order(created_at: :desc).page(params[:page])
  end

  def dashboard
    
  end

  def try_premium
    if current_user.try_premium
      redirect_to dashboard_path, alert: "Trial period activated for 1 day."
    else
      redirect_to dashboard_path, alert: Constant::INELIGIBLE_FOR_FREE_TRIAL_MESSAGE
    end
  end

  def show
    response = HTTParty.get("https://graph.facebook.com/#{@post.page_id}?fields=name,picture{url}&access_token=#{@post.user.token}")
    @url = response.parsed_response["picture"]["data"]["url"] rescue false
    @name = response.parsed_response["name"]
    return redirect_to myposts_path, notice: Constant::INVALID_OPERATION_MESSAGE if @post.nil?
  end

  def stop_post
  	@post.stop("stopped_by_user")
  	return redirect_to myposts_path, notice: Constant::POST_STOPPED_MESSAGE
  end

  def cancel_scheduled_post
    if @post.scheduled?
      @post.cancel_scheduled
      return redirect_to myposts_path, notice: Constant::SCHEDULE_CANCELLED_MESSAGE
    else
      return redirect_to myposts_path, notice: Constant::INVALID_OPERATION_MESSAGE
    end
  end

  private

  def set_post
    @post = Post.find_by_id(params[:post_id]) 
    return redirect_to root_path, notice: Constant::PAGE_NOT_FOUND_MESSAGE if @post.nil?
  end

  def authorize_user!
    redirect_to root_path, notice: Constant::AUTHORIZATION_FAILED_MESSAGE unless current_user == @post.user
  end
end
