class EditorsController < ApplicationController
  
  before_action :authenticate_editor!
  before_action :set_post, except: [:lives_list, :users_list]

  def lives_list
    @posts = Post.live
  end

  def users_list
    @users = User.all.order(id: :desc).page(params[:page])
  end

  def edit_post
    
  end

  def update_post
    if @post.update(default_message: params["post"]["default_message"])
      redirect_to editors_lives_list_path, notice: "Successfully updated post" 
    else
      redirect_to editors_lives_list_path, notice: "Failed to update post" 
    end
  end

  private

  def set_post
    @post = Post.live.find_by_id(params[:post_id]) 
    redirect_to editors_lives_list_path, alert: "Selected Post is not live" if @post.nil?
  end

end