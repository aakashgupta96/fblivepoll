class NotifyMailer < ApplicationMailer
	default from: "fblivepoll@gmail.com"

	def new_post(email_id,link)
		@link = link
		mail(to: email_id, subject: "New post from Shuriken Live")
	end
end
