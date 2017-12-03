class Template < ActiveRecord::Base
	has_many :posts
	has_many :features, dependent: :destroy

	enum category: [:poll, :loop_video, :url_video]

	def premium?
		UserTemplate.where(template_id: self.id, user_role: User.roles["member"]).empty? ? true : false
	end

	def self.premium(templates)
		premium_template_ids = premium_template_ids_from templates
		Template.where("id in (?)",premium_template_ids)
	end

	def self.free(templates)
		free_template_ids = free_template_ids_from templates
		Template.where("id in (?)",free_template_ids)
	end

	def self.free_template_ids_from(templates)
		free_template_ids = UserTemplate.where(user_role: User.roles["member"]).pluck(:template_id)
		free_template_ids = free_template_ids.to_set.intersection(templates.pluck(:id))
	end

	def self.premium_template_ids_from templates
		premium_template_ids = Template.all.pluck(:id) - UserTemplate.where(user_role: User.roles["member"]).pluck(:template_id)
		premium_template_ids = premium_template_ids.to_set.intersection(templates.pluck(:id))
	end

end
