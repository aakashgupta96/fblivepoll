class LoopVideosController < ApplicationController
  
  before_action :set_post, except: [:new, :create, :templates]
  before_action :authenticate_user!
  before_action :authorize_user! , except: [:new, :create, :templates]
  before_action :check_slots, only: [:create]

  def templates
    @templates = Template.loop_video.order(id: :desc)
  end

  def new
  	@post = Post.new
    @template = Template.loop_video.find_by_id(params[:template])
    return redirect_to '/#pluginCarousel', notice: "Invalid Selection of Template" if @template.nil?
    @pages = current_user.pages
  end

  def create
    @post = Post.new(post_params)
    @post.category = "loop_video"
    @post.user = current_user
    @post.template = Template.loop_video.find_by_id(params[:post][:template_id])
    @post.status = "scheduled" if params["post"]["scheduled"]=="on"

    if @post.save
      if (@post.status != "scheduled" and @post.can_start?)
        if @post.start 
          return redirect_to submit_loop_video_path(@post.id)
        else
          return redirect_to root_path, notice: "Facebook declined your request. Please visit My Post section to see the status." 
        end
      end
      return redirect_to submit_loop_video_path(@post.id) if @post.scheduled?
      return redirect_to root_path, notice: "Sorry! All slots are taken. You can schedule your post and it will be posted after scheduled time as soon as a slot will be available OR try after sometime."
    else 
      return redirect_to new_loop_video_path,notice: "Invalid Details"
    end
  end


  def submit
  end

end
