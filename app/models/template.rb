class Template < ActiveRecord::Base
	has_many :posts
	has_many :features

	enum category: [:poll, :loop_video, :url_video]

	def premium?
		UserTemplate.where(template_id: self.id, user_role: User.roles["member"]).empty? ? true : false
	end

end
