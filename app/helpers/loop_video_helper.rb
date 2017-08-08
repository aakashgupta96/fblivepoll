module LoopVideoHelper
	
	def hour_limit
		if current_user.admin?
			23
		elsif current_user.ultimate?
			7
		elsif current_user.premium?
			3
		elsif current_user.donor?
			1
		else
			0
		end
	end

	def file_size_limit
		if current_user.admin? || current_user.ultimate?
			2000.megabytes
		elsif current_user.premium?
			100.megabytes
		elsif current_user.donor?
			500.megabytes
		else
			100.megabytes
		end
	end

end
