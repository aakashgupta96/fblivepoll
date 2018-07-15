class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable
  devise :omniauthable, omniauth_providers: [:facebook]

  paginates_per Constant::USER_PER_PAGE
  
  has_many :posts, dependent: :destroy
  has_many :live_streams, through: :posts
  has_many :payments, dependent: :destroy
  enum role: [:member, :donor, :admin, :premium, :ultimate]

  PERMISSIONS = ["manage_pages", "publish_pages", "pages_show_list", "publish_to_groups", "publish_video"]
  
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
  def subscription_expired?
    return (self.member? or (Time.now.to_date > self.subscription_date + self.subscription_duration))
  end

  def self.expire_subscription
    paid_users = User.donor + User.premium + User.ultimate
    paid_users.each do |u|
      u.member! if u.subscription_expired?
    end
  end

  def has_granted_permissions
    ret = HTTParty.get("https://graph.facebook.com/#{self.uid}/permissions?access_token=#{self.token}").parsed_response['data']
    pages_show_list = publish_pages = manage_pages = false
    required_permissions = Set.new(PERMISSIONS)
    unless ret.nil? 
      ret.each do |item|
        required_permissions.delete(item["permission"]) if (required_permissions.include?(item["permission"]) && item["status"] == "granted")
      end    
    end
    return (required_permissions.size == 0)
  end

  def pages
    temp = Array.new()
    attempts = 0
    begin
      graph = Koala::Facebook::API.new(self.token)
      response = graph.get_object('me?fields=accounts.limit(500){parent_page}')
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

  def groups
    temp = Array.new()
    attempts = 0
    begin
      graph = Koala::Facebook::API.new(self.token)
      response = graph.get_object('me/groups?fields=administrator&limit=500')
      if response.nil? || response.size==0
        temp
      else
        ids = Array.new
        response.each do |hash| 
          ids << hash['id'] if hash["administrator"] == true
        end
        until ids.empty?
          query = "?ids=#{ids.first(49).join(',')}&fields=picture{url},name"
          ids = ids - ids.slice(0..48)
          response = graph.get_object(query)
          response.each do |group_attrs|
            group_hash = {"name"=> group_attrs.second["name"], "id" => group_attrs.second["id"], "image" => group_attrs.second["picture"]["data"]["url"]}
            temp << group_hash
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

  def timeline
    temp = Array.new()
    attempts = 0
    begin
      graph = Koala::Facebook::API.new(self.token)
      response = graph.get_object('me')
      if response.nil? || response.size==0
        temp
      else
        ids = [response["id"]]
        until ids.empty?
          query = "?ids=#{ids.first(49).join(',')}&fields=picture{url},name"
          ids = ids - ids.slice(0..48)
          response = graph.get_object(query)
          response.each do |group_attrs|
            group_hash = {"name"=> group_attrs.second["name"], "id" => group_attrs.second["id"], "image" => group_attrs.second["picture"]["data"]["url"]}
            temp << group_hash
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

  def live_stream_page_limit
    if member?
      Constant::MEMBER_LIVE_STREAM_LIMIT
    elsif donor?
      Constant::DONOR_LIVE_STREAM_LIMIT
    elsif premium?
      Constant::PREMIUM_LIVE_STREAM_LIMIT
    elsif ultimate?
      Constant::ULTIMATE_LIVE_STREAM_LIMIT
    else
      Constant::ADMIN_LIVE_STREAM_LIMIT
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

  def worker_available?
    queued_jobs = Resque.size("stream_job")
    available_workers = Resque.workers.select{|worker|  worker.queues.include?("stream_job") && !worker.working?}.count
    if available_workers > queued_jobs
      return true
    else #No slot is available for user
      if self.member?
        return false
      else
        #Checking if any worker is in closing phase
        Resque.workers.select{|worker|  worker.queues.include?("stream_job") && worker.working?}.each do |worker|
          return true if Post.live.find_by_id(worker.job["payload"]["args"].first).nil?
        end
        #Trying to make slot for premium user
        posts = Post.live.joins(:user).where(users: {role: "member"})
        post_with_earliest_start_time = posts.where(started_at: posts.minimum(:started_at))
        if post_with_earliest_start_time.empty?
          return false
        else
          post_with_earliest_start_time.first.stop
          return true
        end
      end
    end
  end

end
