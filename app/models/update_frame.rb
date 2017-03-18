class UpdateFrame
  include Magick
  @queue = :update_frame

  def self.perform(post_id)
    pid = Process.fork do
      UpdateFrame.work post_id  
    end
    Process.wait
  end

  def self.work(post_id)
    Resque.logger = Logger.new(Rails.root.join("log").join("update").join(post_id.to_s).to_s)
    post = Post.find(post_id)
    graph = post.graph_with_page_token
    counters = post.counters
    fields=""
    if counters.length>0
      txt = Draw.new
      txt.pointsize = 25
      txt.fill = post.counter_color
      txt.font_weight = Magick::BoldWeight
      counters.each do |counter|
        fields += "reactions.type(#{counter.reaction.upcase}).limit(0).summary(total_count).as(#{counter.reaction}),"
      end
      fields[fields.size-1]=""
    end
    offset = [nil,40,33,25,20,15,7,0] 
    loop do 
      begin
        if counters.length>0
          ids = [] 
          # shared_post_ids = graph.graph_call("#{video_id}?fields=sharedposts{id}")["sharedposts"]["data"] rescue false
          # ids = shared_post_ids.collect {|u| u["id"]} if shared_post_ids.class == Array
          ids.push(post.video_id)
          frame = ImageList.new("public/uploads/post/#{post.id}/frame.png")
          count_hash = graph.graph_call("?ids=#{ids.join(',')}&fields=#{fields}")
          if count_hash.size == 0
            Resque.logger.info "Stopping post after its deletion"
            post.stop("Deleted from FB")
          end
          counters.each do |counter|
            count = UpdateFrame.retrieve(count_hash,counter.reaction)
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
      sleep(3)
    end
  end

  def self.retrieve(count_hash,reaction) 
    count = 0
    count_hash.each do |key,value|
      count += value["#{reaction}"]["summary"]["total_count"]
    end
    return count
  end

end
