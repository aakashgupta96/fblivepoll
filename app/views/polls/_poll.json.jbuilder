json.extract! post, :id, :key, :title, :duration, :start_time, :created_at, :updated_at
json.url post_url(post, format: :json)