class DestroyErroneousPosts
	@queue = :destroy_erroneous_posts

	def self.perform(args=nil)
	  Post.drafted.where("created_at <= ?", Time.now - 6.hours).destroy_all
	end

end