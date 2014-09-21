require 'sinatra'
require 'json'
require 'redis'
require 'digest/md5'
require 'nokogiri'
require 'twilio-ruby'

uri = URI.parse(ENV["REDISCLOUD_URL"])
redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

@client = Twilio::REST::Client.new ENV["account_sid"], ENV["auth_token"]

get '/' do
  send_file File.join(settings.public_folder, 'home.html')
end

get '/create' do
  send_file File.join(settings.public_folder, 'create.html')
end

get '/new' do
  # we should check for duplicates
  s_id = Digest::MD5.hexdigest(params["schedule"])[0,7]
  redis.set(s_id, params["schedule"])
  redis.set("#{s_id}:organizer", params["organizer"])
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

get '/setup/:s_id/notify/' do
  @s_id = params["s_id"]
  erb :sendout
end

post '/setup/:s_id/notify/' do
  redis.get("#{s_id}:num_subs").to_i.times do |i|
    @client.messages.create(
      :from => '+12268871500',
      :to => redis.get("#{s_id}:sub_#{i}"),
      :body => params["message"]
    )
  end
  redirect "/list/#{s_id}"
end

get '/list/:s_id' do
  @s_id = params["s_id"]
  @redis = redis
  @schedule_name = redis.get(params["s_id"])
  erb :events
end

get '/view' do
  redirect "/view/#{params['v_code']}"
end

get '/view/:s_id' do
  @s_id = params["s_id"]
  @redis = redis
  @schedule_name = redis.get(params["s_id"])
  @organizer = redis.get("#{params["s_id"]}:organizer")
  erb :public_view
end

get '/twilio_sms' do
  # send schedule
  s_id = params["Body"]
  message = "#{redis.get(s_id)} by #{redis.get("#{s_id}:organizer")}\n\n"
  redis.get("#{s_id}:num_events").to_i.times do |i|
    message << redis.get("#{s_id}:event_#{i}:time") + " : " + redis.get("#{s_id}:event_#{i}:name") + " @ " + redis.get("#{s_id}:event_#{i}:location") + "\n"
  end
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.Response{
      xml.Message message
    }
  end
  
  # subscribe
  redis.set("#{s_id}:sub_#{redis.get("#{s_id}:num_subs").to_i}", params["From"])
  redis.incr("#{s_id}:num_subs")
  
  builder.to_xml
end