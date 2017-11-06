class PollsController < ApplicationController

  before_action :set_post, except: [:new, :create, :templates]
  before_action :authenticate_user!
  before_action :authorize_user! , except: [:new, :create, :templates]
  before_action :check_slots_and_concurrent_eligibility_of_user, only: [:create]
  before_action :check_for_eligibility_of_free_posts, only: [:new, :create]
  
  require 'base64'
  
  def new
    @post = Post.new
    @template = Template.poll.find_by_id(params[:template])
    return redirect_to poll_templates_path, notice: Constant::INVALID_TEMPLATE_MESSAGE if @template.nil?
    return redirect_to poll_templates_path, notice: Constant::UNAUTHORIZED_USER_FOR_TEMPLATE_MESSAGE unless current_user.can_use_template(@template)
    @template.image_count.times {@post.images.build}
    set_user_pages
  end

  def templates
    @templates = ordered_templates_accoding_to_user(Template.poll)
  end

  def frame
    if @post.template.id != 0
      return redirect_to root_path , notice: Constant::PAGE_NOT_FOUND_MESSAGE
    end
  end

  def save_canvas
    reactions = params[:reaction]
    @post.counters.delete_all
    
    unless reactions.nil? 
      reactions.each do |reaction,cordinates|
        @post.counters  << Counter.create(reaction: reaction, x: cordinates[:x].to_i, y: cordinates[:y].to_i)
      end
    end
    @post.update(counter_color: params[:color])
    data = params[:data_uri]
    #return redirect_to frame_path(@post.id), notice: 'Error occured while saving post' if data.nil?
    image_data = Base64.decode64(data['data:image/png;base64,'.length .. -1])

    path = File.join(Rails.root,'public','uploads','post',@post.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    File.open(File.join(path,"frame.png"),'wb') do |f|
      f.write image_data
    end
    @post.template = Template.poll.first
    @post.image = File.open(File.join(path,"frame.png"))
    FileUtils.rm("#{path}/frame.png")
    return save_and_redirect
  end

  def submit
  end
  
  def create
    temp = post_params
    @post = Post.new(temp)
    @post.category = "poll"
    @post.user = current_user
    @post.template = Template.poll.find_by_id(params[:post][:template_id])
    @post.status = "scheduled" if params["post"]["scheduled"]=="on"
    if @post.scheduled?
      @post.start_time = DateTime.new(temp["start_time(1i)"].to_i,temp["start_time(2i)"].to_i,temp["start_time(3i)"].to_i,temp["start_time(4i)"].to_i,temp["start_time(5i)"].to_i,0,params["post"]["timezone"])
    else
      @post.start_time = DateTime.now
    end
    if @post.save
      return redirect_to frame_path(@post.id) if @post.template.id == 0
      @post.take_screenshot_of_frame
      return save_and_redirect
    else
      return redirect_to new_poll_path, notice: "Invalid Details"
    end
  end

  def update
    if @post.update(post_params)
      redirect_to frame_path(@post.id), notice: 'Post was successfully updated.'
    else
      render :edit
    end
  end

  private

  def save_and_redirect
    if @post.save
      if (@post.status != "scheduled" and @post.can_start?)
        if @post.start 
          return redirect_to submit_poll_path(@post.id)
        else
          return redirect_to root_path, alert: Constant::FB_DECLINED_REQUEST_MESSAGE
        end
      end
      return redirect_to submit_poll_path(@post.id) if @post.scheduled?
      return redirect_to root_path, alert: Constant::NO_SLOT_AVAILABLE_MESSAGE
    else 
      return redirect_to frame_path(@post.id), notice: 'Error occured while saving post'
    end
  end

end