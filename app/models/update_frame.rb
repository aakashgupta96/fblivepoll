class UpdateFrame

  include Magick

  @queue = :update_frame

  def self.perform(post_id)


    pid = Process.fork do
      UpdateFrame.work post_id  
    end
    Process.wait
  end

  def self.work post_id
    
    Resque.logger = Logger.new(Rails.root.join("log").join("update").join(post_id.to_s).to_s)
    post = Post.find(post_id)
    @graph = Koala::Facebook::API.new(post.user.token)
    
    counters = post.counters
    if(counters.length > 0)
      txt = Draw.new
      txt.pointsize = 25
      txt.fill = post.counter_color
      txt.font_weight = Magick::BoldWeight
    end
    offset = [nil,40,33,25,20,15,7,0]  
    loop do 
    
      begin
      
        sleep(1)
      
        if counters.length>0
          
          reactions = @graph.get_object("#{post.video_id}/reactions?limit=10000000")
          frame = ImageList.new("public/uploads/post/#{post.id}/frame.png")
          counters.each do |counter|
            count = UpdateFrame.retrieve(counter.reaction,reactions)
            frame.annotate(txt,0,0,counter.x+offset[count.to_s.length],counter.y+23,count.to_s)
          end
          
          frame.write("public/uploads/post/#{post.id}/frame1.tmp.png")
          %x[mv "public/uploads/post/#{post.id}/frame1.tmp.png" "public/uploads/post/#{post.id}/frame1.png"]
    
        end
        
      rescue Exception => e
        Resque.logger.info "Error message is #{e.message}"
        Resque.logger.info "Error class is #{e.class}"
        retry
      end
    end

  end

  def self.retrieve x,reactions
    count = 0;
    x = x.upcase
    
    return 0 if reactions.nil?
     
    reactions.each do |i|
      count = count + 1 if x == i["type"]
    end
    return count
  end

end
