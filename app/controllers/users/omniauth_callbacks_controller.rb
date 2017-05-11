class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      @user.email = request.env["omniauth.auth"].info.email unless request.env["omniauth.auth"].info.email.nil?
      @user.token = request.env["omniauth.auth"].credentials.token
      @user.save!
      if @user.has_granted_permissions
        sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
        set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
      else
        redirect_to root_path, notice: "Please try again and grant all the required permissions to continue"
      end
    else
      #session["devise.facebook_data"] = request.env["omniauth.auth"]
      #redirect_to new_user_registration_url
      redirect_to root_path
    end
  end

  def failure
    redirect_to root_path, notice: "Please try again"
  end
  # You should also create an action method in this controller like this:
  # def twitter
  # end

  # More info at:
  # https://github.com/plataformatec/devise#omniauth

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
