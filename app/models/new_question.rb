class NewQuestion
	@queue = :new_question
	@support = ["info@swarnimtouch.com"]
	
	def self.perform(username,phone,user_email_id,message)
		question_details = {username: username,phone: phone, user_email_id: user_email_id, message: message}
		@support.each do |email|
			AdminMailer.new_question(email,question_details).deliver_now
		end
	end

end
