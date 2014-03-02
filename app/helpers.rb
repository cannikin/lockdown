helpers do

  # Starts a websocket and sets handlers
  def start_websocket
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
          # logger.info "Socket opened: #{ws.to_s}"
        if settings.respond_to? :guarddog
          status_response = settings.guarddog.status
            # logger.info "Status response: #{status_response.inspect}"
          guarddog_reponse = settings.guarddog_parser.parse(status_response, :log => false)
            # logger.info "GuarddogParser response: #{guarddog_reponse.inspect}"
          ws.send guarddog_reponse.to_json
        end
      end
      ws.onmessage do |msg|
          # logger.info "WebSocket message received: #{msg.inspect}"
        response = settings.web_socket_parser.parse(msg)
          # logger.info "SocketParser response: #{response.inspect}"
        send_to_all response unless response.empty?
      end
      ws.onclose do
        settings.sockets.delete(ws)
          # logger.info "Socket closed: #{ws.to_s}"
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
    if !settings.timer_running and settings.respond_to? :guarddog
      settings.guarddog.connect!
      EM.add_periodic_timer(settings.poll_tick) do
        guarddog_response = settings.guarddog.poll
          logger.info "Guarddog message received: #{guarddog_response.inspect}"
        events = settings.guarddog_parser.parse(guarddog_response)
          logger.info "GuarddogParser response: #{events.inspect}"
        send_to_all(events) unless events.empty?
      end
      EM.add_shutdown_hook do
        settings.guarddog.close!
      end
      settings.timer_running = true
    end
  end

  def class_for_sensor(sensor)
    classes = [sensor.type, sensor.layout.orientation]
    classes << 'closed' if sensor.value == sensor.base_state
    classes << 'open' if sensor.value != sensor.base_state
    return classes.join(' ')
  end

  def style_for_sensor(sensor)
    "left: #{sensor.layout.left.to_s}px; top: #{sensor.layout.top.to_s}px"
  end

end
