class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable
  devise :omniauthable, omniauth_providers: [:facebook]

  paginates_per Constant::USER_PER_PAGE
  
  has_many :posts, dependent: :destroy
  has_many :payments, dependent: :destroy

  enum role: [:member, :donor, :admin, :premium, :ultimate]
  
  scope :banned, ->{ where(banned: true) }

  def can_use_template(template)
    UserTemplate.where(template_id: template.id, user_role: User.roles[self.role]).empty? ? false : true
  end

  def can_make_free_video?
    if self.member?
      return self.free_videos_left > 0
    else
      return true
    end
  end

  def ban!
    self.update(banned: true)
  end

  def unban!
    self.update(banned: false)
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = "#{auth.uid}@#{auth.provider}.com"
      user.password = Devise.friendly_token[0,20]
      user.token = auth.credentials.token
      user.name = auth.info.name
      # assuming the user model has a name
      #user.image = auth.info.image # assuming the user model has an image
      # If you are using confirmable and the provider(s) you use validate emails, 
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end
  end

  def eligible_to_try_premium?
    return false #disabling this feature
    #self.member? and !self.premium_tried
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def self.expire_subscription
    paid_users = User.donor + User.premium + User.ultimate
    paid_users.each do |u|
      u.member! if Time.now > (u.subscription_date + u.subscription_duration)
    end
  end

  def has_granted_permissions
    ret = HTTParty.get("https://graph.facebook.com/#{self.uid}/permissions?access_token=#{self.token}").parsed_response['data']
    pages_show_list = publish_pages = manage_pages = false
    unless ret.nil? 
      ret.each do |item|
        if item["permission"] == "publish_pages" && item["status"] == "granted"
          publish_pages = true
        elsif item["permission"] == "manage_pages" && item["status"] == "granted"
          manage_pages = true
        elsif item["permission"] == "pages_show_list" && item["status"] == "granted"
          pages_show_list = true
        end
      end
    end
    return (publish_pages && manage_pages && pages_show_list)
  end

  def pages
    temp = Array.new()
    attempts = 0
    begin
      graph = Koala::Facebook::API.new(self.token)
      response = graph.get_object('me?fields=accounts.limit(100){parent_page}')
      if response.nil? || response["accounts"].nil?
      	temp
      else
      	page_ids = response["accounts"]["data"]
        ids = Array.new
        page_ids.each do |hash| 
          ids << hash['id']
        end
        until ids.empty?
          query = "?ids=#{ids.first(49).join(',')}&fields=picture{url},name"
          ids = ids - ids.slice(0..48)
          response = graph.get_object(query)
  	      response.each do |page_attrs|
  	        page_hash = {"name"=> page_attrs.second["name"], "id" => page_attrs.second["id"], "image" => page_attrs.second["picture"]["data"]["url"]}
  	        temp << page_hash
  	      end
        end
	      temp
	    end
    rescue Exception => e
    	attempts += 1
      retry if attempts <= 3
      raise e 
    end
  end

  def has_live_post_in_limit?
    live_users_posts = Post.live.where(user_id: self.id).count
    if  (self.member? and  live_users_posts < Constant::MEMBER_POST_LIMIT) ||
        (self.donor? and  live_users_posts < Constant::DONOR_POST_LIMIT) ||
        (self.premium? and  live_users_posts < Constant::PREMIUM_POST_LIMIT) ||
        (self.ultimate? and  live_users_posts < Constant::ULTIMATE_POST_LIMIT) ||
        (self.admin? and  live_users_posts < Constant::ADMIN_POST_LIMIT)
      true
    else 
      false
    end
  end

  def has_scheduled_post_in_limit?
    scheduled_posts = Post.scheduled.where(user_id: self.id).count
    if  (self.member? and  scheduled_posts < Constant::MEMBER_SCHEDULED_POST_LIMIT) ||
        (self.donor? and  scheduled_posts < Constant::DONOR_SCHEDULED_POST_LIMIT) ||
        (self.premium? and  scheduled_posts < Constant::PREMIUM_SCHEDULED_POST_LIMIT) ||
        (self.ultimate? and  scheduled_posts < Constant::ULTIMATE_SCHEDULED_POST_LIMIT) ||
        (self.admin? and  scheduled_posts < Constant::ADMIN_SCHEDULED_POST_LIMIT)
      true
    else 
      false
    end
  end

  def try_premium
    if eligible_to_try_premium?
      self.subscription_duration = 1
      self.subscription_date = Date.current
      self.role = "premium"
      self.premium_tried = true
      self.save
    end
  end

end
