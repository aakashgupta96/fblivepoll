class NotifyAdmins
	@queue = :notify_admins
	@support = ["support@shurikenlive.com"]
	@admins = ["aakash@shurikenlive.com"]
	

	def self.perform(username,phone,user_email_id,message)
		# link = "www.facebook.com/#{video_id}"
		# @admins.each do |email|
		# 	AdminMailer.new_post(email,link).deliver_now
		# end
		question_details = {username: username,phone: phone, user_email_id: user_email_id, message: message}
		@support.each do |email|
			AdminMailer.new_question(email,question_details).deliver_now
		end
	end

end
