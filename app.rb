require 'sinatra'
require 'json'
require 'redis'

redis = Redis.new(:url => ENV["REDISTOGO_URL"])

get '/set/:var' do
  redis.set("test", params["var"])
end

get '/' do
  redis.get("test")
end

get '/event/:id' do
  events = {"event_id" => params["id"], events: {"event1" => "12:30", "event2" => "12:45"}}
  events.to_json
end