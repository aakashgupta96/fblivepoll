class NotifyAdmins
	@queue = :notify_admins
	@admins = ["aakash@shurikenlive.com"]
	def self.perform(video_id)
		link = "www.facebook.com/#{video_id}"
		@admins.each do |email|
			NotifyMailer.new_post(email,link).deliver_now
		end
	end
end
