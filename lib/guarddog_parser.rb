# Parses response output from Guarddog

class GuarddogParser

  def parse(events, options={})
    options = { :log => true }.merge(options)
    output = []

    if events.any?
      log_events(events) if options[:log]
      events.each do |event|
        update_sensor(event)
        case event['result']['type']
        when 'egress'
          output << egress_state_change(event)
        end
      end
    end
    output.compact
  end

private

  def log_events(events)
    events.each do |event|
      Event.create :type => event['result']['type'],
                   :data => events['result'].to_json,
                   :created_at => Time.now
    end
  end

  def update_sensor(event)
    if sensor = Sensor.where(:arduino_id => event['result']['id'].to_i).first
      sensor.update(:value => event['result']['value'], :updated_at => Time.now)
    end
  end

  def egress_state_change(event)
    if sensor = Sensor.where(:arduino_id => event['result']['id']).first
      { :event => 'egress', :data => { :id => sensor.id, :value => sensor.value }}
    end
  end

end
