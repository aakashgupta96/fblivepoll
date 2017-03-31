class UpdateFrame
  include Magick
  @queue = :update_frame

  def self.perform(post_id)
    
    @post = Post.find_by_id(post_id) #Instance variable so that erb can access it
    @images = @post.images#Prepare an html for the frame of this post
    
    erb_file = Rails.root.to_s + "/public#{@post.template.path}/frame.html.erb" #Path of erb file to be rendered
    html_file = Rails.root.to_s + "/public/uploads/post/#{@post.id}/frame.html" #=>"target file name"
    erb_str = File.read(erb_file)
    namespace = OpenStruct.new(post: @post, images: @images)
    result = ERB.new(erb_str)
    result = result.result(namespace.instance_eval { binding })

    File.open(html_file, 'w') do |f|
      f.write(result)
    end
    
    #Start updating frame by taking screenshots
    headless = Headless.new(display: rand(100))
    headless.start
    #puts "Headless display is #{headless.display}"
    driver = Selenium::WebDriver.for :chrome
    driver.navigate.to "#{ENV["domain"]}/uploads/post/#{@post.id}/frame.html"
    driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
    driver.manage.window.size = Selenium::WebDriver::Dimension.new(800,518)

    frame_path = "public/uploads/post/#{@post.id}/frame.png"
    if @post.audio.url.nil?
      audio_path = "public/silent.aac"
    else
      audio_path = "public/uploads/post/#{@post.id}"
      %x[$HOME/bin/ffmpeg -i "#{audio_path}/audio.aac" -codec:a aac -ac 1 -ar 44100 -b:a 128k "#{audio_path}/final.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
      %x[rm #{audio_path}/audio.aac]
      %x[$HOME/bin/ffmpeg -stream_loop 10000 -i "#{audio_path}/final.aac" -c copy -t 14400 "#{audio_path}/long.aac" 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}]
      audio_path = "public/uploads/post/#{@post.id}/long.aac"
    end

    command = "$HOME/bin/ffmpeg -y -s 1280x720 -r 24 -f x11grab -i :#{headless.display} -i #{audio_path} -codec:a aac -ac 1 -ar 44100 -b:a 128k -r 24 -g 48 -vcodec libx264 -pix_fmt yuv420p -filter:v 'crop=800:450:0:66' -profile:v high -vb 1500k -bufsize 6000k -maxrate 6000k -deinterlace -preset veryfast -f flv '#{@post.key}' 2> #{Rails.root.join('log').join('stream').join(@post.id.to_s).to_s}"
    pid = Process.spawn(command)
    ffmpeg_id = %x[pgrep -P #{pid}]
    @post.update(process_id: ffmpeg_id.strip)
    duration = (@post.duration-30.years).to_i
    loop do
      break if (Process.exists?(ffmpeg_id) == false)
      elapsed_time = %x[ps -p #{pid} -o etime=]
      elapsed_time = UpdateFrame.convert_to_sec(elapsed_time.strip!)
      if(elapsed_time >= duration)
        @post.stop
        break 
      end
      sleep(1)
    end
    headless.destroy
    driver.quit
    unless @post.audio.url.nil?
      %x[rm #{audio_path}]
    end
  end

  def self.convert_to_sec(time)
    a,b,c = time.split(":").map{|str| str.to_i}
    return ((a*3600)+(b*60)+c) unless c.nil?
    return ((a*60) + b) unless b.nil?
    return a
  end

end
