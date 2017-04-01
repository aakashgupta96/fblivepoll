class PollsController < ApplicationController

  before_action :set_post, except: [:new, :create]
  before_action :authenticate_user!
  before_action :authorize_user! , except: [:new, :create]
  
  
  require 'base64'
  
  def new
    @post = Post.new
    @pages = current_user.pages
  end

  def frame
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
    @post.template = Template.first
    @post.image = File.open(File.join(path,"frame.png"))
    if @post.save
      (@post.start and return redirect_to submit_poll_path) if (@post.status != "scheduled" and @post.can_start?)
      return redirect_to submit_poll_path if @post.status == "scheduled"
      return redirect_to root_path, notice: "Sorry! All slots are taken. Please try after sometime."
    else 
      return redirect_to frame_path(@post.id), notice: 'Error occured while saving post'
    end
  end

  def submit
  end
  
  def create
    @post = Post.new(post_params)
    @post.category = "poll"
    @post.user = current_user
    @post.status = "scheduled" if params["post"]["scheduled"]=="on"
    if @post.save
      return redirect_to frame_path(@post.id)
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

end