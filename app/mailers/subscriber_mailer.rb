class SubscriberMailer < ApplicationMailer
	default from: "liveshuriken@gmail.com"

	def loop_video(email_id)
		mail(to: email_id, subject: "Shuriken Live: New feature")
	end

end
