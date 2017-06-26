module LoopVideoHelper
	
	def hour_limit
		if current_user.admin? || current_user.premium?
			3
		elsif current_user.donor?
			1
		else
			0
		end
	end

	def file_size_limit
		if current_user.admin?
			1000.megabytes
		elsif current_user.premium?
			500.megabytes
		elsif current_user.donor?
			200.megabytes
		else
			100.megabytes
		end
	end

end
