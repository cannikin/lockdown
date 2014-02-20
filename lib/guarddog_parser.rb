# Parses response output from Guarddog

class GuarddogParser

  def initialize

  end

  def parse(events)
    output = []
    if events.any?
      log_events(events)
      events.each do |event|
        case event['result']['type']
        when 'egress'
          output << egress_state_change(event)
        end
      end
    end
    output
  end

private

  def log_events(events)
    events.each do |event|
      Event.create :arduino_id => event['result']['id'],
                   :type       => event['result']['type'],
                   :value      => event['result']['value'],
                   :millis     => event['result']['millis'],
                   :created_at => Time.now
      Sensor.where(:arduino_id => event['result']['id'].to_i).first.update(:value => event['result']['value'], :updated_at => Time.now)
    end
  end

  def egress_state_change(event)
    { :event => 'egress', :data => Sensor.where(:arduino_id => event['result']['id']).naked.first }
  end

end
