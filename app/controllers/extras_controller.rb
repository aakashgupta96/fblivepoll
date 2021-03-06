class ExtrasController < ApplicationController
	
	def invalid
    redirect_to root_path, notice: Constant::PAGE_NOT_FOUND_MESSAGE
  end

  def home
		@templates = ordered_templates_accoding_to_user(Template.active.all)
		@clients = FbPage.big.order(fan_count: :desc).limit(8)
  end
  
	def privacy
	end
		
	def clients
		@clients = FbPage.big.order(fan_count: :desc).page(params[:page])
	end

	def terms
	end

	def faqs
	end
	
	def demo
	end

	def pricing
	end

	def ask_question
		Resque.enqueue(NewQuestion,params[:username],params[:phone],params[:email],params[:message])
    respond_to do |format|
      format.js
    end
	end

	def validate_url
		render :json => Post.validate_url(params[:source_url])
  end

end