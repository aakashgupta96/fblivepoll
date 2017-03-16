class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable
  devise :omniauthable, :omniauth_providers => [:facebook]

  has_many :posts

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
    ret.each do |item|
      if item["permission"] == "publish_pages" && item["status"] == "granted"
        publish_pages = true
      elsif item["permission"] == "manage_pages" && item["status"] == "granted"
        manage_pages = true
      elsif item["permission"] == "pages_show_list" && item["status"] == "granted"
        pages_show_list = true
      end
    end
    return (publish_pages && manage_pages && pages_show_list)
  end

  def pages
    temp = Array.new()
    begin
      @graph = Koala::Facebook::API.new(self.token)
      page_ids = @graph.get_object('me?fields=accounts.limit(100){parent_page}')["accounts"]["data"]
      page_ids.each do |page_id|
        page_hash = Hash.new()
        page_attrs = @graph.get_object("#{page_id['id']}?fields=picture{url},name")
        page_hash["name"] = page_attrs["name"]
        page_hash["id"] = page_attrs["id"]
        page_hash["image"] = page_attrs["picture"]["data"]["url"]
        temp << page_hash
      end
    rescue
    end
    return temp
  end

end
