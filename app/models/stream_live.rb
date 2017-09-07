class StreamLive
  @queue = :stream_live

  def self.perform(post_id)
    %x[pulseaudio -D]
    @post = Post.find_by_id(post_id)
    path = File.join(Rails.root,'log','stream')
    FileUtils.mkdir_p(path) unless File.exist?(path)
    path = File.join(Rails.root,'public','uploads','post',@post.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
   
    if Rails.env.production?
      command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :99.0+0,72 -f alsa -i hw:0,1 -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 2500k -r 24 -g 48 -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
    else
      command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :99.0+0,72 -i 'public/silent.aac' -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 2500k -r 24 -g 48 -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -f flv '#{@post.key.split(':80').join}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
    end
    
    driver,headless = @post.open_in_browser
    start_time = Time.now
    loop do #For respawning process on connection error
      pid = Process.spawn(command)
      sleep(20)
      @post.reload
      ffmpeg_id = %x[pgrep -P #{pid}]
      #puts "ffmpeg id is #{ffmpeg_id}"
      if @post.live
        #puts "making status live of post now"
        @post.live! 
      end
      query = "https://graph.facebook.com/v2.8/?ids=#{@post.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{@post.user.token}"
      nil_count = 0
      restart_process = false
      loop do
        #puts "entered inside loop"
        @post.reload
        
        #Checking whether duration of post has completed or not
        #puts "checking for elapsed time"
        elapsed_time = Time.now - start_time
        duration = (@post.duration-30.years).to_i
        if(elapsed_time >= duration)
          #puts "time completed"
          @post.stop
          break 
        end

        #Checking if reloading browser is required
        if @post.reload_browser
          #puts "reloading browser"
          driver.navigate.refresh
          @post.update(reload_browser: false)
        end
        
        #Checking whether process has not ended unexpectedly
        if(ffmpeg_id.empty? || !Process.exists?(ffmpeg_id))
          #puts "FFMPEG Process not found"
          if @post.live_on_fb?
            #Case 1 : Connection broke from our side => Respawn the process
            #puts "retrying"
            restart_process = true
          elsif @post.ended_on_fb?
            #puts "live video ended manually"
            #Case 2 : Connection was closed by FB because video ended succesfully
            #Reasons can be 1. User used fb directly or used our panel or admin ended the video
            @post.stop
          else
            #puts "live video deleted from fb"
            #Case 3 : Connection was closed by FB
            #Reasons can be 1. Session Invalidated 2. Deleted from FB 
            @post.stop("unknown")
          end
          break
        end
        
        # if ((Process.exists?(ffmpeg_id) == false) && !@post.stopped_by_user? && !@post.published?)
        #   @post.stop("unknown") if @post.live
        #   break
        # end

        #Checking whether post exists on fb and user token is valid or not (Seems redundant to me)
        begin
          #puts "hitting api"
          status = HTTParty.get(query)
          if status.parsed_response["#{@post.video_id}"].nil?
            nil_count += 1
            if nil_count > 3
              @post.stop("unknown")
              break
            end
          else
            nil_count = 0
          end
        rescue
         #Ignored 
        end

        #Checking whether post is manually ended or not
        # if (@post.live == false)
        #   puts "live flag was found to be false"
        #   break
        # end
        sleep(10)
      end #End of inside loop

      unless restart_process
        begin 
          Process.kill("SIGKILL",ffmpeg_id.to_i)
        rescue
          #Ignored if process not found  
        end
        break
      end
    end
    #puts "work ended"
    driver.quit
    headless.destroy
  end
end
