class AdminsController < ApplicationController
	before_action :authenticate_admin!
	before_action :set_post, except: [:dashboard, :panel]

	def dashboard
		@posts = Post.order(created_at: :desc).page(params[:page])
	end

	def panel
		@posts = Post.order(created_at: :desc).first(100)
	end

	def start_post
		@post.start
		return redirect_to admins_panel_path, notice: "Live Video has been pushed to QUEUE."
	end

	def cancel_scheduled_post
		if @post.status == "scheduled"
      @post.cancel_scheduled
      return redirect_to admins_panel_path, notice: "Your scheduled post has been successfully cancelled"
    else
      return redirect_to admins_panel_path, notice: "Invalid operation for the selected post"
    end
	end

	def destroy_post
		@post.destroy
		return redirect_to admins_panel_path, notice: "Live Video has been successfully destroyed."
	end

	def stop_post
		@post.stop
		return redirect_to admins_panel_path, notice: "Live Video has been successfully stopped."
	end

	private

  def set_post
    @post = Post.find_by_id(params[:post_id]) 
    return redirect_to admins_panel_path, notice: "Page requested not found" if @post.nil?
  end

end
