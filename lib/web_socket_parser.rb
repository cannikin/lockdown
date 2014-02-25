# Parses messages from the client

class WebSocketParser

  def parse(raw_message, options={})
    options = { :log => true }.merge(options)
    message = JSON.parse(raw_message)
    log_event(message) if options[:log]
    output = []

    case message['event']
    when 'change_mode'
      Setting.first.update(:mode => message['data']['mode'])
      output << { :event => 'change_mode', :data => { :mode => message['data']['mode'] }}
    end
    return output
  end

private

  def log_event(message)
    Event.create :type => message['event'],
                 :data => message.to_json,
                 :created_at => Time.now
  end

end
