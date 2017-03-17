class FailureMailer < ApplicationMailer
	default from: "liveshuriken@gmail.com"

	def new_post(email_id)
		mail(to: email_id, subject: "Insufficient workers: Shuriken Live")
	end
end
