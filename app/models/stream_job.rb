class StreamJob
  @queue = :stream_job

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
      rtmp_keys = []
      @post.live_streams.queued.each do |ls|
        rtmp_keys << "[f=flv\:onfail=ignore]#{ls.key}"
      end
      rtmp_keys = rtmp_keys.join("|")
      if source_live
        if Constant::RTMP_TEMPLATE_IDS.include?(@post.template.id)
          command = "$HOME/bin/ffmpeg -re -i '#{@post.get_file_url}' -codec:a aac -ac 1 -ar 44100 -b:a 96k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 1000k -r 24 -g 48 -f flv '#{@post.live_streams.first.key}' 2>> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
        else
          command = "$HOME/bin/ffmpeg -re -i '#{@post.get_file_url}' -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 1500k -r 24 -g 48 -f tee -map 0:v -map 0:a '#{rtmp_keys}' 2>> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
        end
      else
        if Constant::RTMP_TEMPLATE_IDS.include?(@post.template.id)
          command = "$HOME/bin/ffmpeg -s 1280x720 -r 24 -f x11grab -i :#{headless.display}.0+0,66 -f alsa -ac 1 -i hw:0,1 -codec:a aac -ar 44100 -b:a 96k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 1000k -r 24 -g 48 -f flv '#{@post.live_streams.first.key}' 2>> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
        else
          command = "$HOME/bin/ffmpeg -s 1280x720 -r 24 -f x11grab -i :#{headless.display}.0+0,66 -f alsa -ac 1 -i hw:0,1 -codec:a aac -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 1500k -r 24 -g 48 -f tee -map 0:v -map 1:a '#{rtmp_keys}' 2>> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
        end
      end
    else
      rtmp_keys = []
      @post.live_streams.queued.each do |ls|
        rtmp_keys << "[f=flv\:onfail=ignore]#{ls.key.split(':80').join}"
      end
      rtmp_keys = rtmp_keys.join("|")
      if source_live
        if Constant::RTMP_TEMPLATE_IDS.include?(@post.template.id)
          command = "$HOME/bin/ffmpeg -re -i '#{@post.get_file_url}' -codec:a aac -ac 1 -ar 44100 -b:a 96k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 1000k -r 24 -g 48 -f flv '#{@post.live_streams.first.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
        else
          command = "$HOME/bin/ffmpeg -re -i '#{@post.get_file_url}' -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 1500k -r 24 -g 48 -f tee -map 0:v -map 0:a '#{rtmp_keys}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
        end
      else
        if Constant::RTMP_TEMPLATE_IDS.include?(@post.template.id)
          command = "$HOME/bin/ffmpeg -s 1300x720 -r 24 -f x11grab -i :#{headless.display}.0+0,66 -i 'public/silent.aac' -ac 1 -codec:a aac -ar 44100 -b:a 96k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 1000k -r 24 -g 48 -f flv '#{@post.live_streams.first.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
        else
          command = "$HOME/bin/ffmpeg -s 1300x720 -r 24 -f x11grab -i :#{headless.display}.0+0,66 -i 'public/silent.aac' -ac 1 -codec:a aac -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 1500k -r 24 -g 48 -f tee -map 0:v -map 1:a '#{rtmp_keys}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
        end
      end
    end
    to_fix_alsa = true
    start_time_initialized = false
    start_time = nil
    loop do #For respawning process on connection error
      pid = Process.spawn(command)
      #Logic to navigate to post.html after ffmpeg process has started
      if (!source_live and to_fix_alsa)
        sleep(5)
        prefix = @post.get_html_url_prefix("chrome")
        driver.get "#{prefix}#{@post.html.url}"
        to_fix_alsa = false
      end
      unless start_time_initialized
        @post.mark_live_on_fb
        start_time = Time.now
        @post.update(started_at: start_time)
        start_time_initialized = true
      end
      @post.reload
      ffmpeg_id = %x[pgrep -P #{pid}]
      @post.change_live_streams(from: "queued", to: "live") if @post.live
      nil_count = 0
      restart_process = false
      loop do
        #close_any_firefox_message(headless.display) unless source_live
        @post.reload
        
        #Checking whether duration of post has completed or not
        #puts "checking for elapsed time"
        elapsed_time = Time.now - start_time
        duration = (@post.duration-30.years).to_i
        if(elapsed_time >= duration)
          @post.stop
          break 
        end
        
        #Checking whether post is manually ended or not
        unless @post.live
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
            #Case 2 : Connection was closed by FB because all live_streams ended.
            #Reasons can be 1. User used fb directly 2. or used our panel 3. admin ended the video 4. User session invalidated by FB.
            #and some live streams may have been deleted since last status update task.
            @post.live_streams.live.each do |ls|
              ls.stop
              ls.update_status
            end
            @post.stop
          else
            #Case 3 : Connection was closed by FB
            #Reasons can be 1. Session Invalidated 2. Deleted from FB 
            @post.stop("unknown")
          end
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
    @post.published!
    @post.user.update(free_videos_left: @post.user.free_videos_left - 1) if @post.user.member?
    driver.quit unless source_live
    headless.destroy unless source_live
    if Rails.env.production?
      chromePids = %x[pidof chrome]
      target_ids = chromePids.strip
      %x[kill -9 #{target_ids}]
    end
  end

  # def self.close_any_firefox_message(display)
  #   begin
  #     %x[DISPLAY=':#{display}' xdotool mousemove 1280 100 click 1]
  #     %x[DISPLAY=':#{display}' xdotool mousemove 1290 800 click 1]
  #   rescue
  #     #Ignore
  #   end
  # end

end
