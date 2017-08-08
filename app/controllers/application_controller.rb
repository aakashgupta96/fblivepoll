class ApplicationController < ActionController::Base
  #before_action :configure_permitted_parameters, if: :devise_controller?
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_action :set_raven_context
  protect_from_forgery with: :exception
  
  def after_sign_in_path_for(resource)
    return root_path if resource.class == User
    '/admins/panel' 
  end

  def worker_available?
    queued_jobs = Resque.size("update_frame")
    available_workers = Resque.workers.select{|worker|  worker.queues.first=="update_frame" && !worker.working?}.count
    return available_workers > queued_jobs
  end

  protected

  def check_slots
    if current_user.is_already_live?
      redirect_to root_path, notice: "You already have one ongoing live post. Please try after that live video ends."
    elsif  current_user.has_scheduled_post?
      redirect_to root_path, notice: "You already have one scheduled post. Please try after that post is published."
    elsif (params["post"]["scheduled"]=="on" || worker_available?)
      true
    else
      redirect_to root_path, notice: "Sorry! All slots are taken. You can schedule your post and it will be posted after scheduled time as soon as a slot will be available OR try after sometime."
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end
  
  def set_post
    @post = Post.find_by_id(params[:post_id]) 
    if @post.nil?
      return redirect_to root_path, notice: "Page requested not found"
    end
  end

  def post_params
    params.require(:post).permit(:title,:caption,:page_id,:duration,:start_time,:audio,:category,:video,:image, :background, images_attributes: [:file, :reaction, :name])
  end

  def authenticate_user!
    redirect_to root_path, notice: "You need to sign in before continuing" unless user_signed_in?
  end

  def authorize_user!
    redirect_to root_path, notice: "Unauthorized" unless current_user == @post.user
  end

  private

  def set_raven_context
    user_id = current_user ? current_user.id : nil
    Raven.user_context(id: user_id)
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

end
