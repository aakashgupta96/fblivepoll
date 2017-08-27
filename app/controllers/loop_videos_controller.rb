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
    return redirect_to '/#pluginCarousel', notice: Constant::INVALID_TEMPLATE_MESSAGE if @template.nil?
    return redirect_to loop_video_templates_path, notice: Constant::UNAUTHORIZED_USER_FOR_TEMPLATE_MESSAGE unless current_user.can_use_template(@template)
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
          return redirect_to root_path, alert: Constant::FB_DECLINED_REQUEST_MESSAGE
        end
      end
      return redirect_to submit_loop_video_path(@post.id) if @post.scheduled?
      return redirect_to root_path, alert: Constant::NO_SLOT_AVAILABLE_MESSAGE
    else 
      return redirect_to new_loop_video_path,notice: "Invalid Details"
    end
  end


  def submit
  end

end
