class UpdateCaptions
	@queue = :update_captions

	def self.perform(args=nil)
	  LiveStream.update_caption_for_site_credits
	end

end