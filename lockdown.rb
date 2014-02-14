require 'sinatra'
require 'sinatra-websocket'
require './guarddog'

set :server, 'thin'
set :sockets, []
set :timer_running, false
set :poll_tick, 0.5
set :arduino, Guarddog.new('/dev/tty.usbmodem1411')

get '/' do
  start_polling unless settings.timer_running

  if !request.websocket?
    haml :index
  else
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
        ws.send settings.arduino.status.to_json
      end
      ws.onmessage do |msg|
        send_to_all "Message received: #{msg}"
      end
      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
  end
end

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
    EM.add_periodic_timer(settings.poll_tick) do
      last = settings.arduino.poll
      send_to_all(last.to_json) if last != []
    end
    EM.add_shutdown_hook do
      settings.arduino.close
    end
    settings.timer_running = true
  end

end
