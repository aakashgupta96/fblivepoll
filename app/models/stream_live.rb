class StreamLive
  @queue = :stream_live

  def self.perform(post_id)
    %x[pulseaudio -D]
    @post = Post.find_by_id(post_id)
    path = File.join(Rails.root,'log','stream')
    FileUtils.mkdir_p(path) unless File.exist?(path)
    path = File.join(Rails.root,'public','uploads','post',@post.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    
    youtube_live = @post.youtube_live_to_fb?
    driver,headless = @post.open_in_browser unless youtube_live
    
    if Rails.env.production?
      if youtube_live
        command = "$HOME/bin/ffmpeg -i '#{@post.get_file_url}' -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 2000k -r 24 -g 48 -async 1 -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      else
        command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :#{headless.display}.0+0,76 -f alsa -i hw:0,1 -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 2000k -r 24 -g 48 -async 1 -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      end
    else
      if youtube_live
        command = "$HOME/bin/ffmpeg -i '#{@post.get_file_url}' -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 2000k -r 24 -g 48 -async 1 -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      else
        command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :#{headless.display}.0+0,76 -i 'public/silent.aac' -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 2000k -r 24 -g 48 -async 1 -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -f flv '#{@post.key.split(':80').join}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      end
    end
    

    start_time = Time.now
    loop do #For respawning process on connection error
      pid = Process.spawn(command)
      sleep(20)
      @post.reload
      ffmpeg_id = %x[pgrep -P #{pid}]
      @post.live! if @post.live
      query = "https://graph.facebook.com/v2.8/?ids=#{@post.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{@post.user.token}"
      nil_count = 0
      restart_process = false
      loop do
        close_any_firefox_message(headless.display) unless youtube_live
        @post.reload
        
        #Checking whether duration of post has completed or not
        #puts "checking for elapsed time"
        elapsed_time = Time.now - start_time
        duration = (@post.duration-30.years).to_i
        if(elapsed_time >= duration)
          @post.stop
          break 
        end

        #Checking if reloading browser is required
        if !youtube_live && @post.reload_browser
          driver.navigate.refresh
          @post.update(reload_browser: false)
        end
        
        #Checking whether process has not ended unexpectedly
        if(ffmpeg_id.empty? || !Process.exists?(ffmpeg_id))
          if Constant::RTMP_TEMPLATE_IDS.include?(@post.template.id) || @post.live_on_fb?
            #Case 1 : Connection broke from our side => Respawn the process
            #puts "retrying"
            restart_process = true
          elsif @post.ended_on_fb?
            #Case 2 : Connection was closed by FB because video ended succesfully
            #Reasons can be 1. User used fb directly or used our panel or admin ended the video
            @post.stop
          else
            #Case 3 : Connection was closed by FB
            #Reasons can be 1. Session Invalidated 2. Deleted from FB 
            @post.stop("unknown")
          end
          break
        end
        
        #Checking whether post exists on fb and user token is valid or not (Seems redundant to me)
        unless Constant::RTMP_TEMPLATE_IDS.include?(@post.template.id)
          begin
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
        end

        #Checking whether post is manually ended or not
        if (@post.live == false)
          break
        end
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
    @post.user.update(free_videos_left: @post.user.free_videos_left - 1) if @post.user.member?
    driver.quit unless youtube_live
    headless.destroy unless youtube_live
    firefoxPids = %x[pidof firefox]
    target_ids = firefoxPids.strip
    %x[kill -9 #{target_ids}]
  end

  def self.close_any_firefox_message(display)
    begin
      %x[DISPLAY=':#{display}' xdotool mousemove 1280 100 click 1]
      %x[DISPLAY=':#{display}' xdotool mousemove 1290 800 click 1]
    rescue
      #Ignore
    end
  end

end
