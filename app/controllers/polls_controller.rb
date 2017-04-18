class PollsController < ApplicationController

  before_action :set_post, except: [:new, :create]
  before_action :authenticate_user!
  before_action :authorize_user! , except: [:new, :create]
  
  
  require 'base64'
  
  def new
    @post = Post.new
    @template = Template.find_by_id(params[:template])
    return redirect_to '/#pluginCarousel', notice: "Invalid Selection of Template" if @template.nil?
    @template.image_count.times {@post.images.build}
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
    
    return save_and_redirect

  end

  def submit

  end
  
  def create
    @post = Post.new(post_params)
    @post.category = "poll"
    @post.user = current_user
    @post.template = Template.find_by_id(params[:post][:template_id])
    @post.status = "scheduled" if params["post"]["scheduled"]=="on"
    if @post.save
      return redirect_to frame_path(@post.id) if @post.template.id == 0
      take_screenshot_of_frame(@post.id)
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
      (@post.start and return redirect_to submit_poll_path(@post.id)) if (@post.status != "scheduled" and @post.can_start?)
      return redirect_to submit_poll_path(@post.id) if @post.status == "scheduled"
      return redirect_to root_path, notice: "Sorry! All slots are taken. Please try after sometime."
    else 
      return redirect_to frame_path(@post.id), notice: 'Error occured while saving post'
    end
  end

  def take_screenshot_of_frame post_id
    @post = Post.find_by_id(post_id) #Instance variable so that erb can access it
    @images = @post.images#Prepare an html for the frame of this post
    erb_file = Rails.root.to_s + "/public#{@post.template.path}/frame.html.erb" #Path of erb file to be rendered
    html_file = Rails.root.to_s + "/public/uploads/post/#{@post.id}/frame.html" #=>"target file name"
    erb_str = File.read(erb_file)
    namespace = OpenStruct.new(post: @post, images: @images)
    result = ERB.new(erb_str)
    result = result.result(namespace.instance_eval { binding })
    path = File.join(Rails.root,'public','uploads','post',@post.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    File.open(html_file, 'w') do |f|
      f.write(result)
    end
    
    headless = Headless.new(display: rand(100))
    headless.start
    #if (ENV["domain"] == "https://new.shurikenlive.com")
      driver = Selenium::WebDriver.for :firefox
    #else
     # driver = Selenium::WebDriver.for :chrome
    #end
    driver.navigate.to "file://#{Rails.root.to_s}/public/uploads/post/#{@post.id}/frame.html"
    driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
    driver.manage.window.size = Selenium::WebDriver::Dimension.new(800,518)
    path = File.join(Rails.root,'public','uploads','post',post_id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    driver.save_screenshot("public/uploads/post/#{post_id}/frame.png" )
    driver.quit
    headless.destroy
  end

end