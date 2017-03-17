class PostsController < ApplicationController

  before_action :set_post, except: [:home, :steps, :new, :create]
  before_action :authenticate_user!, except: [:home, :steps]
  before_action :authorize_user! , only: [:frame, :save_canvas, :submit]
  before_action :set_graph, only: [:new, :save_canvas, :submit]
  
  require 'base64'
  
  def invalid
    redirect_to root_path, notice: "Page requested not found"
  end

  def home    
  end
  
  def steps
  end

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
    image_data = Base64.decode64(data['data:image/png;base64,'.length .. -1])

    path = File.join(Rails.root,'public','uploads','post',@post.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    File.open(File.join(path,"frame.png"),'wb') do |f|
      f.write image_data
    end
    File.open(File.join(path,"frame1.png"), 'wb') do |f|
      f.write image_data
    end
    
    if @post.can_start?
      @post.start 
      redirect_to submit_path
    else
      Resque.enqueue(NotifyAdmins,false) 
      redirect_to root_path, notice: "Sorry! All slots are taken. Please try after sometime."
    end
  end

  def submit
  end
  
  def create
    @post = Post.new(post_params)
    @post.user = current_user
    if @post.save
      return redirect_to frame_path(@post.id)
    else
      return redirect_to new_post_path, alert: "Invalid details"
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

    def set_post
      @post = Post.find_by_id(params[:post_id]) 
      if @post.nil?
        return redirect_to root_path, notice: "Page requested not found"
      end
    end

    def post_params
      params.require(:post).permit(:title,:caption,:page_id,:duration,:start_time,:audio)
    end

    def set_graph
      @graph = Koala::Facebook::API.new(current_user.token)
    end

    def authenticate_user!
      redirect_to root_path, notice: "You need to sign in before continuing" unless user_signed_in?
    end

    def authorize_user!
      redirect_to root_path, notice: "Unauthorized" unless current_user == @post.user
    end
end