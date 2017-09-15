module PollsHelper
	
	def audio_file_size_limit
		if current_user.admin? || current_user.ultimate?
			1000.megabytes
		elsif current_user.premium?
			500.megabytes
		elsif current_user.donor?
			200.megabytes
		else
			50.megabytes
		end
	end

end
