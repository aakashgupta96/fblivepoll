class DestroyErroneousPosts
	@queue = :destroy_erroneous_posts

	def self.perform(args=nil)
	  Post.drafted.where("created_at <= ?", Time.now - 6.hours).destroy_all
	  Post.scheduled.where("created_at <= ?", Time.now - 6.hours).each do |p|
	   	p.destroy if p.live_streams.empty?
	 	end
	end

end