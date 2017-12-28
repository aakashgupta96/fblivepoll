class SharedPost < ActiveRecord::Base
	belongs_to :live_stream
	delegate :user, to: :live_stream
	belongs_to :post
end
