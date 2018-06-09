class Message < ActiveRecord::Base
	belongs_to :post
	belongs_to :live_stream

	LIVE_STREAM_STARTED = "Live Stream has started"
	LIVE_STREAM_STOPED = "Live Stream has stopped"

end
