$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'sinatra'
require 'sinatra-websocket'
require 'sinatra/sequel'
require './database'
require './models'
require './helpers'
require 'sinatra/reloader' if development?
require 'guarddog'

set :server, 'thin'
set :sockets, []
set :timer_running, false
set :poll_tick, 0.5
# set :arduino, Guarddog.new(ENV['USB'])

# For SASS stylesheets
get '/*.css' do
  content_type 'text/css', :charset => 'utf-8'
  filename = params[:splat].first
  sass filename.to_sym, :views => "#{settings.root}/public/stylesheets"
end

# Homepage
get '/' do
  # start_polling unless settings.timer_running

  if !request.websocket?
    @mode = Setting.first.mode
    @doors_and_windows = Sensor.filter(:type => ['door', 'window', 'garage-door'])

    haml :index
  else
    # request.websocket do |ws|
    #   ws.onopen do
    #     settings.sockets << ws
    #     ws.send settings.arduino.version.to_json
    #     ws.send settings.arduino.status.to_json
    #   end
    #   ws.onmessage do |msg|
    #     send_to_all "Echo: #{msg}"
    #   end
    #   ws.onclose do
    #     settings.sockets.delete(ws)
    #   end
    # end
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
        send_to_all([{:foo => 'bar'}].to_json)
      end
      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end


# Puts the system into an alarm mode
post '/mode/:mode' do
  Setting.first.update(:mode => params[:mode])
  nil
end


# Get current status of all sensors
get '/status' do
  # @arduino = settings.arduino
  @sockets = settings.sockets
  haml :status
end
