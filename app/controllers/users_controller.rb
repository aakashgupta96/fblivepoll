class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [:stop_post]
  before_action :authorize_user!, only: [:stop_post]
  def posts
  	@posts = current_user.posts.order(created_at: :desc)
  end

  def stop_post
  	@post.stop("Stopped by user")
  	return redirect_to myposts_path, notice: "Live Video has been successfully stopped."
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
