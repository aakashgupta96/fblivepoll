class PostsController < ApplicationController

  before_action :set_post, except: [:home,:steps,:new, :create]
  before_action :authenticate_user!, except: [:home, :steps]
  before_action :authorize_user! , only: [:frame, :save_canvas, :submit]
  before_action :set_graph, only: [:new, :submit]
  require 'base64'
  
  def home    
  end
  
  def steps
  end

  def new
    @post = Post.new
    @pages = Array.new()
    begin
      page_ids = @graph.get_object('me?fields=accounts.limit(100){parent_page}')["accounts"]["data"]
      page_ids.each do |page_id|
        page_hash = Hash.new()
        page_attrs = @graph.get_object("#{page_id['id']}?fields=picture{url},name")
        page_hash["name"] = page_attrs["name"]
        page_hash["id"] = page_attrs["id"]
        page_hash["image"] = page_attrs["picture"]["data"]["url"]
        @pages << page_hash
      end
    rescue
    end  
  end

  def frame  
  end

  def save_canvas
    reactions = params[:reaction]
    @post.counters.delete_all
    
    unless reactions.nil? 
      reactions.each do |reaction,cordinates|
        counter = Counter.create(reaction: reaction, x: cordinates[:x].to_i, y: cordinates[:y].to_i)
        @post.counters << counter
      end
    end
    @post.counter_color = params[:color]
    @post.save!
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
    
    return redirect_to submit_path
  end

  def submit
    byebug
    if workers_available? 
      page_access_token = @graph.get_page_access_token(@post.page_id)
      @graph = Koala::Facebook::API.new(page_access_token)
      video = @graph.graph_call("#{@post.page_id}/live_videos",{status: "LIVE_NOW", description: "#{@post.caption} \nMade with: www.shurikenlive.com", title: @post.title},"post")
      @post.video_id = video["id"]
      @post.key = video["stream_url"]
      @post.save!
      Resque.enqueue(StartStream,@post.id)
      Resque.enqueue(UpdateFrame,@post.id)
      Resque.enqueue(NotifyAdmins,@post.id)
    else
      redirect_to root_path, alert: "Sorry! All slots are taken. Please try after sometime."
      return
    end
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

  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      format.json { head :no_content }
    end
  end



  private
    
    def workers_available?
      start = 0
      update = 0
      Resque::Worker.all.each do |worker| 
        unless worker.working?
          start = 1 if worker.queues.first == "start_stream"
          update = 1 if worker.queues.first == "update_frame"
        end
        return true if start==1 and update==1
      end
      return false
    end

    def set_post
      @post = Post.find_by_id(params[:post_id]) 
      if @post.nil?
        return redirect_to root_path, alert: "Invalid URL"
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