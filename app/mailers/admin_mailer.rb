class AdminMailer < ApplicationMailer
	default from: "support@shurikenlive.com"

	def new_post(email_id,link)
		@link = link
		mail(to: email_id, subject: "New post from Shuriken Live")
	end

	def new_question(email_id,question_details)
		@question_details = question_details
		mail(to: email_id, subject: "New Question for Shuriken Live")
	end

end
