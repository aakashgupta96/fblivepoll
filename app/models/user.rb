class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable
  devise :omniauthable, omniauth_providers: [:facebook]

  has_many :posts, dependent: :destroy
  has_many :payments, dependent: :destroy

  enum role: [:member, :donor, :admin, :premium, :ultimate]
  
  MEMBER_POST_LIMIT = 1
  DONOR_POST_LIMIT = 1
  PREMIUM_POST_LIMIT = 1
  ULTIMATE_POST_LIMIT = 2
  ADMIN_POST_LIMIT = 10

  def can_use_template(template)
    UserTemplate.where(template_id: template.id, user_role: User.roles[self.role]).empty? ? false : true
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

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
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
        query = "?ids=#{ids.first(49).join(',')}&fields=picture{url},name"
        response = graph.get_object(query)
	      response.each do |page_attrs|
	        page_hash = {"name"=> page_attrs.second["name"], "id" => page_attrs.second["id"], "image" => page_attrs.second["picture"]["data"]["url"]}
	        temp << page_hash
	      end
	      temp
	    end
    rescue Exception => e
    	attempts += 1
      retry if attempts <= 3
      raise e 
    end
  end

  def is_already_live?
    live_users_posts = Post.live.where(user_id: self.id).count
    if (self.member? and  live_users_posts < MEMBER_POST_LIMIT) || (self.donor? and  live_users_posts < DONOR_POST_LIMIT) || (self.premium? and  live_users_posts < PREMIUM_POST_LIMIT) || (self.ultimate? and  live_users_posts < ULTIMATE_POST_LIMIT) || (self.admin? and  live_users_posts < ADMIN_POST_LIMIT)
      false
    else 
      true
    end
  end

  def has_scheduled_post?
    Post.scheduled.where(user_id: self.id).empty? ? false: true
  end
end
