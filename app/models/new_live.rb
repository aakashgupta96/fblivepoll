class NewLive
	@queue = :new_live
	@support = ["support@shurikenlive.com"]
	@admins = ["aakash@shurikenlive.com"]
	@editors = ["fahadnasar579@gmail.com","vmahesh20@gmail.com"]

	def self.perform(post_id=nil)
		link = "www.facebook.com/#{Post.find_by_id(post_id).video_id}"
		@editors.each do |email|
			AdminMailer.new_post(email,link).deliver_now
		end
		# question_details = {username: username,phone: phone, user_email_id: user_email_id, message: message}
		# @support.each do |email|
		# 	AdminMailer.new_question(email,question_details).deliver_now
		# end
	end

end
