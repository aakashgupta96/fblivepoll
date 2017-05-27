class UpdateFrame
  #include Magick
  @queue = :update_frame

  def self.perform(post_id)
    %x[pulseaudio -D]
    @post = Post.find_by_id(post_id) #Instance variable so that erb can access it
    path = File.join(Rails.root,'log','stream')
    FileUtils.mkdir_p(path) unless File.exist?(path)
    path = File.join(Rails.root,'public','uploads','post',@post.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    
    # if @post.poll?
    #   if @post.audio.url.nil?
    #     audio_path = "public/silent.aac"
    #   else
    #     local_audio_path = "#{Rails.root.to_s}/public/uploads/post/#{@post.id.to_s}"
    #     if Rails.env.production?
    #       %x[$HOME/bin/ffmpeg -i "#{@post.audio.url}" -codec:a aac -ac 1 -ar 44100 -b:a 128k -y "#{local_audio_path}/final.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
    #     else
    #       %x[$HOME/bin/ffmpeg -i "#{Rails.root.to_s}/public/#{@post.audio.url}" -codec:a aac -ac 1 -ar 44100 -b:a 128k -y "#{local_audio_path}/final.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
    #     end
    #     %x[$HOME/bin/ffmpeg -stream_loop 10000 -i "#{local_audio_path}/final.aac" -c copy -t 14400 -y "#{local_audio_path}/long.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
    #     audio_path = "#{local_audio_path}/long.aac"
    #   end
    # else
    #   local_audio_path = "#{Rails.root.to_s}/public/uploads/post/#{@post.id.to_s}"
    #   if Rails.env.production?
    #     %x[wget #{@post.video.url} -q -O #{local_audio_path}/1.mp4]
    #     %x[$HOME/bin/ffmpeg -stream_loop 10000 -i "#{local_audio_path}/1.mp4" -vn -acodec copy -t 14400 -y "#{local_audio_path}/long.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
    #   else
    #     %x[$HOME/bin/ffmpeg -stream_loop 10000 -i "#{Rails.root.to_s}/public#{@post.video.url}" -vn -acodec copy -t 14400 -y "#{local_audio_path}/long.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
    #   end
    #   audio_path = "#{local_audio_path}/long.aac"
    # end

    # headless = Headless.new #(display: rand(100))
    # headless.start
    # driver = Selenium::WebDriver.for :firefox
    # driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
    # driver.manage.window.size = Selenium::WebDriver::Dimension.new(800,521)
    # driver.navigate.to "file://#{Rails.root.to_s}/public/uploads/post/#{@post.id}/frame.html"
    
    # command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :#{headless.display} -i #{audio_path} -codec:a aac -ac 1 -ar 44100 -b:a 128k -r 24 -g 48 -vcodec libx264 -pix_fmt yuv420p -filter:v 'crop=800:449:0:72' -profile:v high -vb 2000k -bufsize 6000k -maxrate 6000k -deinterlace -preset veryfast -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"  
 
   
    if @post.poll?
      if @post.audio.url.nil?
        audio_path = "public/silent.aac"
      else
        local_audio_path = "#{Rails.root.to_s}/public/uploads/post/#{@post.id.to_s}"
        if Rails.env.production?
          %x[$HOME/bin/ffmpeg -i "#{@post.audio.url}" -codec:a aac -ac 1 -ar 44100 -b:a 128k -y "#{local_audio_path}/final.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
        else
          %x[$HOME/bin/ffmpeg -i "#{Rails.root.to_s}/public/#{@post.audio.url}" -codec:a aac -ac 1 -ar 44100 -b:a 128k -y "#{local_audio_path}/final.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
        end
          %x[$HOME/bin/ffmpeg -stream_loop 10000 -i "#{local_audio_path}/final.aac" -c copy -t 14400 -y "#{local_audio_path}/long.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
          audio_path = "#{local_audio_path}/long.aac"
      end
      command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :99 -i #{audio_path} -codec:a aac -ac 1 -ar 44100 -b:a 128k -r 24 -g 48 -vcodec libx264 -pix_fmt yuv420p -filter:v 'crop=800:448:0:72' -profile:v high -vb 2000k -bufsize 6000k -maxrate 6000k -deinterlace -preset veryfast -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"  
    else
      local_video_path = "#{Rails.root.to_s}/public/uploads/post/#{@post.id.to_s}"
      if Rails.env.production?
        %x[wget #{@post.video.url} -q -O #{local_video_path}/1.mp4]
      end
      video_path = "#{local_video_path}/1.mp4"
      if Rails.env.production?
        command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :99 -f alsa -i hw:0,1 -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -filter:v 'crop=800:448:0:72' -vcodec libx264 -crf 23 -pix_fmt yuv420p -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      else
        command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :99 -i 'public/silent.aac' -preset ultrafast -filter:v 'crop=800:448:0:72' -vcodec libx264 -crf 23 -pix_fmt yuv420p -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
      end
      #command = "$HOME/bin/ffmpeg -re -fflags +genpts -stream_loop -1 -i #{video_path} -s 1280x720 -ac 2 -ar 44100 -codec:a aac -b:a 64k -pix_fmt yuv420p -profile:v high -vb 2000k -bufsize 6000k -maxrate 6000k -deinterlace -vcodec libx264 -preset veryfast -r 24 -g 48 -t 14400 -strict -2 -f flv \"#{@post.key.to_s}\" 2> #{Rails.root.join("log").join("stream").join(@post.id.to_s).to_s}"
    end
    driver,headless = @post.open_in_browser
    pid = Process.spawn(command)
    start_time = Time.now
    sleep(20)
    ffmpeg_id = %x[pgrep -P #{pid}]
    @post.update(status: "live")
    query = "https://graph.facebook.com/v2.8/?ids=#{@post.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{@post.user.token}"
    nil_count = 0
    loop do
      if @post.reload_browser
        driver.navigate.refresh
        @post.update(reload_browser: false)
      end
      if (Process.exists?(ffmpeg_id) == false)
        @post.stop("Post has been deleted or Streaming stopped due to network error") if @post.live
        break
      end
      begin
        status = HTTParty.get(query)
        if status.parsed_response["#{@post.video_id}"].nil?
          nil_count += 1
          if nil_count > 3
            @post.stop("Deleted from FB")
            break
          end
        else
          nil_count = 0
        end
      rescue
        
      end
      @post.reload
      elapsed_time = Time.now - start_time
      duration = (@post.duration-30.years).to_i
      if(elapsed_time >= duration)
        @post.stop
        break 
      end
      if (@post.live == false)
        break
      end
      sleep(10)
    end
    %x[kill -9 #{ffmpeg_id}]
    driver.quit
    headless.destroy  
    if @post.poll?
      unless @post.audio.url.nil?
        %x[rm #{audio_path}]
      end
    else
      %x[rm -f #{video_path}]
    end
  end

end
