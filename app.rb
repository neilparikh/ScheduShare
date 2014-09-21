require 'sinatra'
require 'json'
require 'redis'
require 'digest/md5'
require 'nokogiri'

uri = URI.parse(ENV["REDISCLOUD_URL"])
redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

get '/create' do
  # we should check for duplicates
  s_id = Digest::MD5.hexdigest(params["schedule"])[0,7]
  redis.set(s_id, params["schedule"])
  redirect "/setup/#{s_id}"
end

get '/setup/:s_id' do
  @s_id = params["s_id"]
  erb :add
end

post '/setup/:s_id/add' do
  s_id = params["s_id"]
  redis.set("#{s_id}:event_#{redis.get("#{s_id}:num_events").to_i}:name", params["name"])
  redis.set("#{s_id}:event_#{redis.get("#{s_id}:num_events").to_i}:time", params["time"])
  redis.set("#{s_id}:event_#{redis.get("#{s_id}:num_events").to_i}:location", params["location"])
  redis.incr("#{s_id}:num_events")
  redirect "/list/#{s_id}"
end

get '/list/:s_id' do
  @s_id = params["s_id"]
  @redis = redis
  @schedule_name = redis.get(params["s_id"])
  erb :events
end

get '/view/:s_id' do
  @s_id = params["s_id"]
  @redis = redis
  @schedule_name = redis.get(params["s_id"])
  erb :public_view
end

get '/twilio_sms' do

end