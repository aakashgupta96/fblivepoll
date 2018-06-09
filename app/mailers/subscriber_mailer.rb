class SubscriberMailer < ApplicationMailer
	default from: "support@shurikenlive.com"

	def loop_video(email_id)
		mail(to: email_id, subject: "Shuriken Live: New feature")
	end

end
