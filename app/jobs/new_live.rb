class NewLive
	@queue = :new_live
	@support = ["support@shurikenlive.com"]
	@admins = ["aakash@shurikenlive.com"]
	@editors = ["fahadnasar579@gmail.com"]

	def self.perform(post_id=nil)
		# link = "www.facebook.com/#{Post.find_by_id(post_id).video_id}"
		# @editors.each do |email|
		# 	AdminMailer.new_post(email,link).deliver_now
		# end
	end

end
