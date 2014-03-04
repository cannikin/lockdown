$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__))

require 'sinatra/reloader'
#require 'sinatra-logger'
require 'helpers'
require 'guarddog'
require 'web_socket_parser'
require 'guarddog_parser'
require 'http_parser'
require 'uploader'
require 'comms'

configure :development do
  set :database, 'sqlite://db/development.db'
  $logger = Logger.new STDOUT
end

configure :production do
  set :database, 'sqlite://db/production.db'
  $logger = Logger.new File.join(__FILE__,'log','production.log')
end

require 'database'
require 'models'

set :server, 'thin'
set :sockets, []
set :timer_running, false
set :poll_tick, 1
set :config, Setting.first
set :guarddog, Guarddog.new(ENV['USB']) if ENV['USB']
set :web_socket_parser, WebSocketParser.new(settings)
set :guarddog_parser, GuarddogParser.new(settings)
set :http_parser, HttpParser.new(settings)
set :uploader, Uploader.new(settings.config)
set :mode, settings.config.mode.to_sym
# set :uploader, Uploader.new(settings.config, :callback => proc { |files| Comms.email("New motion images", "New motion images uploaded:\n\n", files.join("\n")) })

Comms.setup(settings.config)

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


# Can be called by anyone to report an event
get '/event/:event' do
    $logger.debug "HTTP event received: #{params.inspect}"
  response = settings.http_parser.parse(params)
    $logger.debug "HttpParser response: #{response.inspect}"
  send_to_all(response) unless response.empty?
  200
end
