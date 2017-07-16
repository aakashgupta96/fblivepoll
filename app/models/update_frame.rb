class UpdateFrame
  @queue = :update_frame

  def self.perform(post_id)
    %x[pulseaudio -D]
    @post = Post.find_by_id(post_id) #Instance variable so that erb can access it
    path = File.join(Rails.root,'log','stream')
    FileUtils.mkdir_p(path) unless File.exist?(path)
    path = File.join(Rails.root,'public','uploads','post',@post.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
   
    if Rails.env.production?
      command = "$HOME/bin/ffmpeg -y -s 800x448 -r 24 -f x11grab -i :99.0+0,72 -f alsa -i hw:0,1 -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 4000k -r 24 -g 48 -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
    else
      command = "$HOME/bin/ffmpeg -y -s 800x448 -r 24 -f x11grab -i :99.0+0,72  -i 'public/silent.aac' -codec:a aac -ac 1 -ar 44100 -b:a 128k -preset ultrafast -vcodec libx264 -pix_fmt yuv420p -vb 4000k -r 24 -g 48 -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
    end
    
    driver,headless = @post.open_in_browser
    pid = Process.spawn(command)
    start_time = Time.now
    sleep(20)
    ffmpeg_id = %x[pgrep -P #{pid}]
    @post.live!
    query = "https://graph.facebook.com/v2.8/?ids=#{@post.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{@post.user.token}"
    nil_count = 0
    loop do
      if @post.reload_browser
        driver.navigate.refresh
        @post.update(reload_browser: false)
      end
      if (Process.exists?(ffmpeg_id) == false)
        @post.stop("unknown") if @post.live
        break
      end
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
  end
end
