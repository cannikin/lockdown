helpers do

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

  def class_for_sensor(sensor)
    classes = [sensor.type, sensor.layout.orientation]
    classes << 'closed' if sensor.value == 0
    classes << 'open' if sensor.value == 1
    return classes.join(' ')
  end

  def style_for_sensor(sensor)
    "left: #{sensor.layout.left.to_s}px; top: #{sensor.layout.top.to_s}px"
  end

end
