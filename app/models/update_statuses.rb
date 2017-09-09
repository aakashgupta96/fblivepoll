class UpdateStatuses
	@queue = :update_statuses

	def self.perform(args=nil)
	  #Update status of posts with unknown statuses
		Post.update_statuses
	end

end
