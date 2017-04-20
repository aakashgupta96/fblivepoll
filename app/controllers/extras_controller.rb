class ExtrasController < ApplicationController
	
	def invalid
    redirect_to root_path, notice: "Page requested not found"
  end

  def home    
  end
  
	def privacy
	end
	
	def terms
	end

	def demo
	end

	def test
		@post = Post.last #Instance variable so that erb can access it
    @images = @post.images
    #Prepare an html for the frame of this post
    erb_file = Rails.root.to_s + "/public#{@post.template.path}/frame.html.erb" #Path of erb file to be rendered
    html_file = Rails.root.to_s + "/public/uploads/post/#{@post.id}/frame.html" #=>"target file name"
    erb_str = File.read(erb_file)
    namespace = OpenStruct.new(post: @post, images: @images)
		result = ERB.new(erb_str)
		result = result.result(namespace.instance_eval { binding })

    File.open(html_file, 'w') do |f|
      f.write(result)
    end
    return redirect_to "http://localhost:3000/uploads/post/#{@post.id}/frame.html"
	end

end