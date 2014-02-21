# Parses messages from the client

class WebSocketParser

  def parse(raw_message)
    message = JSON.parse(raw_message)
    output = []

    case message['event']
    when 'change_mode'
      Setting.first.update(:mode => message['data']['mode'])
      output << { :event => 'change_mode', :data => { :mode => message['data']['mode'] }}
    end
    return output
  end

end
