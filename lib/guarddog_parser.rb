# Parses response output from Guarddog

class GuarddogParser

  def parse(events, options={})
    options = { :log => true }.merge(options)
    output = []

    if events.any?
      log_events(events) if options[:log]
      events.each do |event|
        update_sensor(event)
        case event['event']
        when 'sensor'
          output << sensor_change(event)
        end
      end
    end
    output.compact
  end

private

  def log_events(events)
    events.each do |event|
      Event.create :type => event['event'],
                   :data => event['data'].to_json,
                   :created_at => Time.now
    end
  end

  def update_sensor(event)
    if sensor = Sensor.where(:arduino_id => event['data']['id'].to_i).first
      sensor.update(:value => event['data']['value'], :updated_at => Time.now)
    end
  end

  def sensor_change(event)
    if sensor = Sensor.where(:arduino_id => event['data']['id']).first
      { :event => 'sensor_change', :data => { :id => sensor.id, :name => sensor.name, :value => sensor.value, :base_state => sensor.base_state }}
    end
  end

end
