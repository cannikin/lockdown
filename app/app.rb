$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__))

require 'sinatra/reloader'
#require 'sinatra-logger'
require 'database'
require 'models'
require 'helpers'
require 'guarddog'
require 'web_socket_parser'
require 'guarddog_parser'
require 'pry'
require 'pry-debugger'

set :server, 'thin'
set :sockets, []
set :timer_running, false
set :poll_tick, 0.5
set :guarddog, Guarddog.new(ENV['USB']) if ENV['USB']
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
  start_polling if !settings.timer_running and settings.respond_to?(:guarddog)

  if request.websocket?
    start_websocket
  else
    index
  end
end


# Get current status of all sensors
get '/status' do
  @guarddog = settings.guarddog
  @sockets = settings.sockets
  haml :status
end


get '/motion' do
  Event.create :type => 'motion', :data => params.to_json, :created_at => Time.now
  200
end
