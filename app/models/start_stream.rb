class StartStream

	@queue = :start_stream

	def self.perform(post_id)
		post = Post.find(post_id)
		post.update(status: "live")
		
		if post.poll?
			frame_path = "public/uploads/post/#{post.id}/frame1.png"
			if post.audio.url.nil?
				audio_path = "public/silent.aac"
			else
				audio_path = "public/uploads/post/#{post.id}"
				%x[$HOME/bin/ffmpeg -i "#{audio_path}/audio.aac" -codec:a aac -ac 1 -ar 44100 -b:a 128k "#{audio_path}/final.aac"]
				%x[rm #{audio_path}/audio.aac]
				%x[$HOME/bin/ffmpeg -stream_loop 10000 -i "#{audio_path}/final.aac" -c copy -t 14400 "#{audio_path}/long.aac"]
				audio_path = "public/uploads/post/#{post.id}/long.aac"
			end

			%x[$HOME/bin/ffmpeg -loop 1 -re -y -f image2 -i #{frame_path} -i #{audio_path} -acodec copy -bsf:a aac_adtstoasc -pix_fmt yuv420p -profile:v high -s 1280x720 -vb 400k -maxrate 400k -minrate 400k -bufsize 600k -deinterlace -vcodec libx264 -preset veryfast -g 30 -r 30 -t 14400 -strict -2 -f flv "#{post.key}" 2> #{Rails.root.join("log").join("stream").join(post.id.to_s).to_s} ]
			Resque.workers.each do |worker|
				if worker.working? and worker.queues.first == "update_frame" and worker.job["payload"]["args"].first==post_id
					victim = %x[pgrep -P #{worker.pid}]	
					victim.strip!
					victim = %x[pgrep -P #{victim}]	
					victim.strip!
					%x[kill -9 #{victim.to_i}]
				end
			end
			unless post.audio.url.nil?
				%x[rm #{audio_path}]
			end
		else
			# video_path = "public/uploads/post/#{post_id.to_s}/1.flv" 
			# width = FFMPEG::Movie.new(Rails.root.to_s + "/public" + post.video.url).width
			# width = (width>960 ? 1280 : 640)
			%x[$HOME/bin/ffmpeg -re -fflags +genpts -stream_loop -1 -i #{video_path} -s 1280x720 -ac 2 -ar 44100 -codec:a aac -b:a 64k -pix_fmt yuv420p -profile:v high -vb 1500k -bufsize 6000k -maxrate 6000k -deinterlace -vcodec libx264 -preset veryfast -r 24 -g 48 -t 14400 -strict -2 -f flv "#{post.key}" 2> #{Rails.root.join("log").join("stream").join(post.id.to_s).to_s} ]
			#%x[$HOME/bin/ffmpeg -re -fflags +genpts -stream_loop -1 -i #{video_path} -i "public/logo_#{width}.png" -filter_complex "overlay=W-w-5:H-h-5" -s 1280x720 -ac 2 -ar 44100 -codec:a aac -b:a 64k -pix_fmt yuv420p -profile:v high -vb 1500k -bufsize 6000k -maxrate 6000k -deinterlace -vcodec libx264 -preset veryfast -r 24 -g 48 -t 14400 -strict -2 -f flv "#{post.key}" 2> #{Rails.root.join("log").join("stream").join(post.id.to_s).to_s} ]
			#%x[$HOME/bin/ffmpeg -re -fflags +genpts -stream_loop -1 -i 2.mp4 -t 00:05:00 -strict -2 -f flv pipe:1 | ffmpeg -re -i - -i "logo_1280.png" -filter_complex "overlay=W-w-5:H-h-5" -s 1280x720 -ac 2 -ar 44100 -codec:a aac -b:a 64k -pix_fmt yuv420p -profile:v high -vb 1500k -bufsize 6000k -maxrate 6000k -deinterlace -vcodec libx264 -preset veryfast -r 24 -g 48 -f flv "rtmp://rtmp-api.facebook.com:80/rtmp/250736748729969?ds=1&s_l=1&a=ATgdN4ICGXBysECX"]
			%x[rm #{video_path}]
			post.update(status: "published")
		end
	end
end
