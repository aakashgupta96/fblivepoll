class NotifyAdmins
	@queue = :notify_admins
	@admins = ["aakash@shurikenlive.com", "apoorva.11596@gmail.com", "tushar@codingninjas.in"]
	def self.perform(post_id)
		post = Post.find(post_id)
		link = "www.facebook.com/#{post.video_id}"
		@admins.each do |email|
			NotifyMailer.new_post(email,link).deliver_now
		end
	end
end
