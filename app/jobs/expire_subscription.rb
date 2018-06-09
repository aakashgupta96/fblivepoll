class ExpireSubscription
	@queue = :expire_subscription

	def self.perform(args=nil)
	  User.expire_subscription
	end

end