module PollsHelper
	def hour_limit
		if current_user.admin?
			3
		elsif current_user.donor?
			1
		else
			0
		end
	end
end
