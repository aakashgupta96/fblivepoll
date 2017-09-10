class DestroyErroneousPosts
	@queue = :destroy_erroneous_posts

	def self.perform(args=nil)
	  Post.deleted_from_fb.destroy_all
	  Post.request_declined.destroy_all
	end

end