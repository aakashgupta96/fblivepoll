class ApplicationController < ActionController::Base
  #before_action :configure_permitted_parameters, if: :devise_controller?
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_action :set_raven_context
  protect_from_forgery with: :exception
  
  def after_sign_in_path_for(resource)
    if resource.class == User
      dashboard_path
    elsif resource.class  == Moderator
      moderators_panel_path
    elsif resource.class == Editor
      editors_lives_list_path
    else
      root_path
    end
  end

  protected

  def check_slots_and_eligibility_of_user
    if params["post"]["scheduled"] == "on" #User wants to schedule
      if current_user.has_scheduled_post_in_limit?
        return true
      else
        return redirect_to root_path, alert: Constant::ALREADY_SCHEDULED_MESSAGE
      end
    elsif current_user.has_live_post_in_limit? == false #User wants to go live right now but he has already reached his plan limit
      return redirect_to root_path, alert: Constant::ALREADY_LIVE_MESSAGE
    elsif Post.new.worker_available?
      return true
    else
      return redirect_to root_path, alert: Constant::NO_SLOT_AVAILABLE_MESSAGE
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end
  
  def set_post
    @post = Post.find_by_id(params[:post_id]) 
    if @post.nil?
      return redirect_to root_path, notice: Constant::PAGE_NOT_FOUND_MESSAGE
    end
  end

  def post_params
    params.require(:post).permit(:title,:caption,:page_id,:duration,:start_time,:audio,:category,:video,:image,:key,:background,:template_id,link_attributes: [:url],images_attributes: [:file, :reaction, :name])
  end

  def authenticate_user!
    return redirect_to root_path, notice: Constant::AUTHENTICATION_FAILED_MESSAGE unless user_signed_in?
    check_user_if_banned
  end

  def authorize_user!
    redirect_to root_path, alert: Constant::AUTHORIZATION_FAILED_MESSAGE unless current_user == @post.user
  end

  def check_user_if_banned
    redirect_to root_path, alert: Constant::USER_BANNED_MESSAGE if current_user.banned
  end

  def set_user_pages
    begin
      @pages = current_user.pages
    rescue Exception => e
      return redirect_to user_facebook_omniauth_authorize_path
    end
  end

  private

  def set_raven_context
    user_id = current_user ? current_user.id : nil
    Raven.user_context(id: user_id)
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

end