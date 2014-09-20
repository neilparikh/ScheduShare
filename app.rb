require 'sinatra'
require 'json'

get '/event/:id' do
  events = {"event_id" => params["id"], events: {"event1" => "12:30", "event2" => "12:45"}}
  events.to_json
end