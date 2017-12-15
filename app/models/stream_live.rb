class StreamLive
  @queue = :stream_live

  def self.perform(post_id)
    @post = Post.find_by_id(post_id)
    path = File.join(Rails.root,'log','stream')
    FileUtils.mkdir_p(path) unless File.exist?(path)
    path = File.join(Rails.root,'public','uploads','post',@post.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    
    source_live = @post.source_file_is_live?
    unless source_live
        driver,headless = @post.open_in_browser("chrome") 
        driver.navigate.to "http://www.e-try.com/black.htm" #fix for channel count 2 alsa error
        sleep(5)
      end
    if Rails.env.production?
      if source_live
        command = "$HOME/bin/ffmpeg -i '#{@post.get_file_url}' -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 2000k -r 24 -g 48 -f flv '#{@post.key}' 2>> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      else
        command = "$HOME/bin/ffmpeg -s 1280x720 -r 24 -f x11grab -i :#{headless.display}.0+0,66 -f alsa -ac 1 -i hw:0,1 -codec:a aac -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -color_range 2 -vb 2000k -r 24 -g 48 -f flv '#{@post.key}' 2>> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      end
    else
      if source_live
        command = "$HOME/bin/ffmpeg -i '#{@post.get_file_url}' -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 2000k -r 24 -g 48 -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      else
        command = "$HOME/bin/ffmpeg -s 1280x720 -r 24 -f x11grab -i :#{headless.display}.0+0,66 -i 'public/silent.aac' -ac 1 -codec:a aac -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -color_range 2 -vb 2000k -r 24 -g 48 -f flv '#{@post.key.split(':80').join}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      end
    end
    start_time = Time.now
    @post.update(started_at: start_time)
    to_fix_alsa = true
    loop do #For respawning process on connection error
      pid = Process.spawn(command)
      #Logic to navigate to post.html after ffmpeg process has started
      if (!source_live and to_fix_alsa)
        sleep(5)
        prefix = @post.get_html_url_prefix("chrome")
        driver.navigate.to "#{prefix}#{@post.html.url}"
        to_fix_alsa = false
      end
      sleep(20)
      @post.reload
      ffmpeg_id = %x[pgrep -P #{pid}]
      @post.live! if @post.live
      query = "https://graph.facebook.com/v2.8/?ids=#{@post.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{@post.user.token}"
      nil_count = 0
      restart_process = false
      loop do
        #oclose_any_firefox_message(headless.display) unless source_live
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
        if !source_live && @post.reload_browser
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
    driver.quit unless source_live
    headless.destroy unless source_live
    if Rails.env.production?
      chromePids = %x[pidof chrome]
      target_ids = chromePids.strip
      %x[kill -9 #{target_ids}]
    end
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
