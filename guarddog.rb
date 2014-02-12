# Talks to Arduino and reports status updates
require 'serialport'

# lets us query serial.ready? to see if there are any bytes waiting for us or
# serial.nread to tell us how many bytes are available
require 'io/wait'
require 'json'

class Guarddog

  MAX_RETRIES = 3

  attr_reader :serial

  def initialize
    connect
  end

  # connect to the serial port
  def connect
    @serial = SerialPort.new('/dev/tty.usbmodem40111', 9600, 8, 1, SerialPort::NONE)
  end

  # will either return an empty array or all events since the last check
  def poll
    output = []
    retries = 0
    last = ''
    begin
      while serial.ready?
        last = serial.gets.chomp
        output << JSON.parse(last) if validate(last)
      end
      return output
    rescue IOError => e
      retries += 1
      if retries < MAX_RETRIES
        connect
        retry
      else
        raise e
      end
    rescue JSON::ParserError => e
      puts "Bad JSON string: #{last}"
      return []
    end
  end

  # close the connection
  def close
    serial.close
  end

private

  # Validate a message from Arduino
  def validate(message)
    return message['type'] && message['id'] && message['state'] && message['millis']
  end

end
