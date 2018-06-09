class ModeratorsController < ApplicationController

	before_action :authenticate_moderator!
	before_action :set_post, except: [:dashboard, :panel]

	def dashboard
		@posts = Post.order(created_at: :desc).page(params[:page]).includes(:user)
	end

	def panel
		@posts = Post.order(created_at: :desc).limit(100).includes(:user)
	end

	def start_post
		@post.start
		return redirect_to moderators_panel_path, notice: Constant::POST_PUSHED_MESSAGE
	end

	def cancel_scheduled_post
		if @post.scheduled?
      @post.cancel_scheduled
      return redirect_to moderators_panel_path, notice: Constant::SCHEDULE_CANCELLED_MESSAGE
    else
      return redirect_to moderators_panel_path, notice: Constant::INVALID_OPERATION_MESSAGE
    end
	end

	def destroy_post
		@post.destroy
		return redirect_to moderators_panel_path, notice: Constant::POST_DESTROYED_MESSAGE
	end

	def stop_post
		@post.stop
		return redirect_to moderators_panel_path, notice: Constant::POST_STOPPED_MESSAGE
	end

	private

  def set_post
    @post = Post.find_by_id(params[:post_id]) 
    return redirect_to moderators_panel_path, notice: Constant::PAGE_NOT_FOUND_MESSAGE if @post.nil?
  end

end
