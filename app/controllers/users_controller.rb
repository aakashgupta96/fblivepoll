class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, except: [:posts]
  before_action :authorize_user!, except: [:posts]
  def posts
  	@posts = current_user.posts.order(created_at: :desc)
  end

  def stop_post
  	@post.stop("Stopped by user")
  	return redirect_to myposts_path, notice: "Live Video has been successfully stopped."
  end

  def cancel_scheduled_post
    if @post.status == "scheduled"
      @post.cancel_scheduled
      return redirect_to myposts_path, notice: "Your scheduled post has been successfully cancelled"
    else
      return redirect_to myposts_path, notice: "Invalid operation for the selected post"
    end

  end

  private

  def set_post
    @post = Post.find_by_id(params[:post_id]) 
    return redirect_to root_path, notice: "Page requested not found" if @post.nil?
  end

  def authorize_user!
    redirect_to root_path, notice: "Unauthorized" unless current_user == @post.user
  end
end
