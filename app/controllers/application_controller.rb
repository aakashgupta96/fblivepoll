class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  protect_from_forgery with: :exception
  def after_sign_in_path_for(resource)
    return root_path if resource.class == User
    '/admins/dashboard' 
  end

  protected

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
    params.require(:post).permit(:title,:caption,:page_id,:duration,:start_time,:audio,:category,:video,:image)
  end

  def authenticate_user!
    redirect_to root_path, notice: "You need to sign in before continuing" unless user_signed_in?
  end

  def authorize_user!
    redirect_to root_path, notice: "Unauthorized" unless current_user == @post.user
  end

end
