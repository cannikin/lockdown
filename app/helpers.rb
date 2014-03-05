helpers do

  # Starts a websocket and sets handlers
  def start_websocket
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
          $logger.debug "Socket opened: #{ws.to_s}"
        if settings.respond_to? :guarddog
          status_response = settings.guarddog.status
            # $logger.debug "Status response: #{status_response.inspect}"
          guarddog_reponse = settings.guarddog_parser.parse(status_response, :log => false)
            # $logger.debug "GuarddogParser response: #{guarddog_reponse.inspect}"
          ws.send guarddog_reponse.to_json
        end
      end
      ws.onmessage do |msg|
          $logger.debug "WebSocket message received: #{msg.inspect}"
        response = settings.web_socket_parser.parse(msg)
          $logger.debug "SocketParser response: #{response.inspect}"
        send_to_all response unless response.empty?
      end
      ws.onclose do
        settings.sockets.delete(ws)
          $logger.debug "Socket closed: #{ws.to_s}"
      end
    end
  end


  # Returns the html for the page
  def index
    @mode = settings.mode
    @doors_and_windows = Sensor.filter(:type => ['door', 'window', 'garage-door'])
    haml :index
  end


  # Send a message to all websockets
  def send_to_all(message)
    EM.next_tick do
      settings.sockets.each do |s|
        s.send(message.to_json)
      end
    end
  end


  # Start checking for new events every so often
  def start_polling
    settings.guarddog.connect!
    EM.add_periodic_timer(settings.poll_tick) do
      guarddog_response = settings.guarddog.poll
        # $logger.debug "Guarddog message received: #{guarddog_response.inspect}"
      events = settings.guarddog_parser.parse(guarddog_response)
        # $logger.debug "GuarddogParser response: #{events.inspect}"
      send_to_all(events) unless events.empty?
    end
    EM.add_shutdown_hook do
      settings.guarddog.close!
    end
    settings.timer_running = true
  end


  # CSS class for a sensor (whether it's open or closed)
  def class_for_sensor(sensor)
    classes = [sensor.type, sensor.layout.orientation]
    classes << 'closed' if sensor.value == sensor.base_state
    classes << 'open' if sensor.value != sensor.base_state
    return classes.join(' ')
  end


  # Custom CSS styles to position sensor correctly
  def style_for_sensor(sensor)
    "left: #{sensor.layout.left.to_s}px; top: #{sensor.layout.top.to_s}px"
  end


  def day?
    settings.mode == :day
  end

  def night?
    settings.mode == :night
  end

  def away?
    settings.mode == :away
  end

  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    if params[:access_key] == settings.config.access_key
      return true
    else
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and User.where(:username => @auth.credentials.first, :password => @auth.credentials.last).first
    end
  end

end
