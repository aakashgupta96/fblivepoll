module ApplicationHelper
	def current_user_is_donor?
		if current_user
			return current_user.member?	? false : true
		else
			return false
		end
	end

end
