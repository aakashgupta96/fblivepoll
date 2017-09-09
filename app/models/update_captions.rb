class UpdateCaptions
	@queue = :update_captions

	def self.perform(args=nil)
	  Post.update_caption_for_site_credits
	end

end