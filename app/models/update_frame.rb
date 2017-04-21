class UpdateFrame
  #include Magick
  @queue = :update_frame

  def self.perform(post_id)
    @post = Post.find_by_id(post_id) #Instance variable so that erb can access it
    path = File.join(Rails.root,'public','uploads','post',@post.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    path = File.join(Rails.root,'log','stream')
    FileUtils.mkdir_p(path) unless File.exist?(path)
      
    html_file = Rails.root.to_s + "/public/uploads/post/#{@post.id}/frame.html" #=>"target file name"
    @images = @post.images#Prepare an html for the frame of this post
       
    if @post.poll?
      erb_file = Rails.root.to_s + "/public#{@post.template.path}/frame.html.erb" #Path of erb file to be rendered
    else
      erb_file = Rails.root.to_s + "/public/videos/loop_video_frame.html.erb"
    end

    erb_str = File.read(erb_file)
    namespace = OpenStruct.new(post: @post, images: @images)
    result = ERB.new(erb_str)
    result = result.result(namespace.instance_eval { binding })
  
    File.open(html_file, 'w') do |f|
      f.write(result)
    end

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
    else
      local_audio_path = "#{Rails.root.to_s}/public/uploads/post/#{@post.id.to_s}"
      if Rails.env.production?
        %x[wget #{@post.video.url} -q -O #{local_audio_path}/1.mp4]
        %x[$HOME/bin/ffmpeg -stream_loop 10000 -i "#{local_audio_path}/1.mp4" -vn -acodec copy -t 14400 -y "#{local_audio_path}/long.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
      else
        %x[$HOME/bin/ffmpeg -stream_loop 10000 -i "#{Rails.root.to_s}/public#{@post.video.url}" -vn -acodec copy -t 14400 -y "#{local_audio_path}/long.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
      end
      audio_path = "#{local_audio_path}/long.aac"
    end

    headless = Headless.new(display: rand(100))
    headless.start
    driver = Selenium::WebDriver.for :firefox
    driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
    driver.manage.window.size = Selenium::WebDriver::Dimension.new(800,521)
    driver.navigate.to "file://#{Rails.root.to_s}/public/uploads/post/#{@post.id}/frame.html"
    
    command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :#{headless.display} -i #{audio_path} -codec:a aac -ac 1 -ar 44100 -b:a 128k -r 24 -g 48 -vcodec libx264 -pix_fmt yuv420p -filter:v 'crop=800:449:0:72' -profile:v high -vb 2000k -bufsize 6000k -maxrate 6000k -deinterlace -preset veryfast -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"  
    pid = Process.spawn(command)
    sleep(30)
    ffmpeg_id = %x[pgrep -P #{pid}]
    @post.update(status: "live", process_id: ffmpeg_id.strip)
    query = "https://graph.facebook.com/v2.8/?ids=#{@post.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{@post.user.token}"
    duration = (@post.duration-30.years).to_i
    loop do
      if (Process.exists?(ffmpeg_id) == false)
        @post.stop("Streaming stopped due to network error")
        break
      end
      begin
        status = HTTParty.get(query)
        if status.parsed_response["#{@post.video_id}"].nil?
          @post.stop("Deleted from FB")
          break
        end
      rescue
        
      end
      elapsed_time = %x[ps -p #{pid} -o etime=]
      elapsed_time = UpdateFrame.convert_to_sec(elapsed_time.strip!)
      if(elapsed_time >= duration)
        @post.stop
        break 
      end
      @post.reload
      if (@post.live == false)
        break
      end
      sleep(10)
    end
    %x[kill -9 #{@post.process_id}] 
    driver.quit
    headless.destroy
    unless @post.audio.url.nil?
      %x[rm #{audio_path}]
    end
    if @post.loop_video?
      %x[rm -f #{local_audio_path}/1.mp4]
    end
  end

  def self.convert_to_sec(time)
    a,b,c = time.split(":").map{|str| str.to_i}
    return ((a*3600)+(b*60)+c) unless c.nil?
    return ((a*60) + b) unless b.nil?
    return a
  end

end
