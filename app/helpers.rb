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
