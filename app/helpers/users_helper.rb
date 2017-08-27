module UsersHelper
	def user_package_name(user)
		case user.role
		when "member"
			"None"
		when "donor"
			"Donor Pack"
		when "premium"
			"Premium Pack" 
		when "ultimate"
			"Ultimate Pack"
		when "admin"
			"Admin Pack"
		end	
	end
end
