require 'sinatra'
require 'sinatra-websocket'
require './guarddog'
require './egress'

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
    @mode = :day
    @egresses = [Egress.new(1, :door, 141, 140, :'hinge-left-open-down'),
                 Egress.new(2, :window, 238, -9, :horizontal)]

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
  end
end


# Puts the system into an alarm mode
get '/mode/:mode' do

end


# Get current status of all sensors
get '/status' do
  # @arduino = settings.arduino
  @sockets = settings.sockets
  haml :status
end

helpers do

  # Send a message to all websockets
  def send_to_all(message)
    EM.next_tick { settings.sockets.each { |s| s.send(message) } }
  end

  # Start checking for new events every so often
  def start_polling
    settings.arduino.connect!
    EM.add_periodic_timer(settings.poll_tick) do
      last = settings.arduino.poll
      send_to_all(last.to_json) if last != []
    end
    EM.add_shutdown_hook do
      settings.arduino.close!
    end
    settings.timer_running = true
  end

  def class_for_egress(egress)
    egress.type.to_s + ' ' + egress.orientation.to_s
  end

  def style_for_egress(egress)
    "left: #{egress.left.to_s}px; top: #{egress.top.to_s}px"
  end

end
