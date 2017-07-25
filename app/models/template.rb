class Template < ActiveRecord::Base
	has_many :posts
	has_many :features

	enum category: [:poll, :loop_video]
end
