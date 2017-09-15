module LoopVideoHelper

	def video_file_size_limit
		if current_user.admin? || current_user.ultimate?
			2000.megabytes
		elsif current_user.premium?
			1000.megabytes
		elsif current_user.donor?
			500.megabytes
		else
			100.megabytes
		end
	end

end
