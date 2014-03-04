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
require 'http_parser'
require 'uploader'

set :server, 'thin'
set :sockets, []
set :timer_running, false
set :poll_tick, 1
set :guarddog, Guarddog.new(ENV['USB']) if ENV['USB']
set :web_socket_parser, WebSocketParser.new(settings, nil)
set :guarddog_parser, GuarddogParser.new(settings, nil)
set :http_parser, HttpParser.new(settings, nil)
set :mode, Setting.first.mode.to_sym
set :config, Setting.first
set :uploader, Uploader.new(:path => settings.config.image_upload_path, :bucket => settings.config.s3_bucket, :access_key_id => settings.config.s3_access_key_id, :secret_access_key => settings.config.s3_secret_access_key)

before do
  logger.level = Logger::DEBUG
end

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
    protected!
    index
  end
end


# Called by Axis camera when motion is detected, should always return a 200
get '/event' do
  response = settings.http_parser.parse(params)
  send_to_all(response) unless response.empty?
  200
end
