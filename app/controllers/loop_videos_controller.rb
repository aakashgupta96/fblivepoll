class LoopVideosController < ApplicationController
  
  before_action :set_post, except: [:new, :create, :templates]
  before_action :authenticate_user!
  before_action :authorize_user_post! , except: [:new, :create, :templates]
  before_action :check_slots_and_concurrent_eligibility_of_user, only: [:create]
  before_action :check_for_eligibility_of_free_posts, only: [:new, :create]

  def templates
    @templates = ordered_templates_accoding_to_user(Template.where("category in (?)",[Template.categories["url_video"],Template.categories["loop_video"]]))
  end

  def new
  	@post = Post.new
    @template = Template.loop_video.find_by_id(params[:template])
    return redirect_to '/#pluginCarousel', notice: Constant::INVALID_TEMPLATE_MESSAGE if @template.nil?
    return redirect_to loop_video_templates_path, notice: Constant::UNAUTHORIZED_USER_FOR_TEMPLATE_MESSAGE unless current_user.can_use_template(@template)
    set_user_pages
  end

  def create
    temp = post_params
    @post = Post.new(temp)
    @post.category = "loop_video"
    @post.user = current_user
    @post.template = Template.loop_video.find_by_id(params[:post][:template_id])
    @post.status = "scheduled" if params["post"]["scheduled"]=="on"
    if @post.scheduled?
      @post.start_time = DateTime.new(temp["start_time(1i)"].to_i,temp["start_time(2i)"].to_i,temp["start_time(3i)"].to_i,temp["start_time(4i)"].to_i,temp["start_time(5i)"].to_i,0,params["post"]["timezone"])
    else
      @post.start_time = DateTime.now
    end
    if @post.save
      return save_and_redirect if @post.template.id == 9 #start if hybrid template
      return redirect_to select_pages_path(@post.id)
    else 
      return redirect_to new_loop_video_path,notice: "Invalid Details"
    end
  end

  private

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
      return redirect_to dashboard_path, notice: 'Error occured while saving post'
    end
  end

end
