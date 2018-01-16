class NewLive
	@queue = :new_live
	@editors = []

	def self.perform(post_id=nil)
		# link = "www.facebook.com/#{Post.find_by_id(post_id).video_id}"
		# @editors.each do |email|
		# 	AdminMailer.new_post(email,link).deliver_now
		# end
	end

end
