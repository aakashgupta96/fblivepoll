class LoopVideosController < ApplicationController
  
  before_action :set_post, except: [:new, :create]
  before_action :authenticate_user!
  before_action :authorize_user! , except: [:new, :create]
  

  def new
  	@post = Post.new
    @pages = current_user.pages
  end

  def create
    @post = Post.new(post_params)
    @post.category = "loop_video"
    @post.user = current_user
    @post.status = "scheduled" if params["post"]["scheduled"]=="on"

    if @post.save
      (@post.start and return redirect_to submit_loop_video_path(@post.id)) if (@post.status != "scheduled" and @post.can_start?)
      return redirect_to submit_loop_video_path(@post.id) if @post.status == "scheduled"
      return redirect_to root_path, notice: "Sorry! All slots are taken. Please try after sometime."
    else
      redirect_to new_loop_video_path,notice: "Invalid Details"
    end
  end


  def submit
  end

end
