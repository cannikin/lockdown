$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'sinatra'
require 'sinatra-websocket'
require 'sinatra/sequel'
require './database'
require './models'
require './helpers'
require 'sinatra/reloader' if development?
require 'guarddog'
require 'web_socket_parser'
require 'guarddog_parser'
require 'pry'
require 'pry-debugger'

set :server, 'thin'
set :sockets, []
set :timer_running, false
set :poll_tick, 0.5
set :guarddog, Guarddog.new(ENV['USB'])
set :web_socket_parser, WebSocketParser.new
set :guarddog_parser, GuarddogParser.new


# For SASS stylesheets
get '/*.css' do
  content_type 'text/css', :charset => 'utf-8'
  filename = params[:splat].first
  sass filename.to_sym, :views => "#{settings.root}/public/stylesheets"
end


# Homepage
get '/' do
  start_polling unless settings.timer_running

  if !request.websocket?
    @mode = Setting.first.mode
    @doors_and_windows = Sensor.filter(:type => ['door', 'window', 'garage-door'])

    haml :index
  else
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
          logger.info "Socket opened: #{ws.to_s}"
        status_response = settings.guarddog.status
          logger.info "Status response: #{status_response.inspect}"
        guarddog_reponse = settings.guarddog_parser.parse(status_response, :log => false)
          logger.info "GuarddogParser response: #{guarddog_reponse.inspect}"
        ws.send guarddog_reponse.to_json
      end
      ws.onmessage do |msg|
          logger.info "WebSocket message received: #{msg.inspect}"
        response = settings.web_socket_parser.parse(msg)
          logger.info "SocketParser response: #{response.inspect}"
        send_to_all response unless response.empty?
      end
      ws.onclose do
        settings.sockets.delete(ws)
          logger.info "Socket closed: #{ws.to_s}"
      end
    end
  end
end


# Get current status of all sensors
get '/status' do
  @guarddog = settings.guarddog
  @sockets = settings.sockets
  haml :status
end
