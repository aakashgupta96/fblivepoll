class UpdateFbPages
	@queue = :update_fb_pages

	def self.perform(args=nil)
	  FbPage.update_information
	end

end