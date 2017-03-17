class NotifyAdmins
	@queue = :notify_admins
	@admins = ["aakash@shurikenlive.com"]#,"apoorva.11596@gmail.com","tushar@codingninjas.in"]
	def self.perform(success=false,video_id=nil)
		link = "www.facebook.com/#{video_id}"
		@admins.each do |email|
			SuccessMailer.new_post(email,link).deliver_now if success
			FailureMailer.new_post(email).deliver_now unless success
		end
	end
end
