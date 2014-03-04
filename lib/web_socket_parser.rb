# Parses messages from the client

class WebSocketParser < Parser

  def parse(raw_message, options={})
    options = { :log => true }.merge(options)
    message = JSON.parse(raw_message)
    log_event(message) if options[:log]
    output = []

    case message['event']
    when 'change_mode'
      Setting.first.update(:mode => message['data']['mode'])
      settings.mode = message['data']['mode'].to_sym
      output << { :event => 'change_mode', :data => { :mode => message['data']['mode'] }}
    end
    return output
  end

end
