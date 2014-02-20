# Talks to Arduino speaking the Lockdown protocol. Turns JSON messages from
# the Arduino into Ruby hashes

require 'serialport'
require 'json'
# lets us query serial.ready? to see if there are any bytes waiting for us or
# serial.nread to tell us how many bytes are available
require 'io/wait'

class Guarddog

  class PortRequiredError < StandardError
    def initialize(msg="A USB port is required to connect to. e.g. '/dev/tty.usbmodem14001'")
      super(msg)
    end
  end

  METHODS = [:status, :version]

  attr_reader :serial, :port


  def initialize(port=nil)
    raise PortRequiredError if port.nil?
    @port = port
  end


  # connect to the serial port
  def connect!
    @serial = SerialPort.new(port, 57600, 8, 1, SerialPort::NONE)
  end


  # will either return an empty array or all events since the last check
  def poll
    output = []
    retries = 0
    last = ''
    while serial.ready?
      last = serial.gets.chomp
      output << JSON.parse(last) if validate(last)
    end
    return output
  end


  # close the connection
  def close!
    serial.close
    puts "Serial closed."
  end


  # Pass other method calls over to the Arduino
  def method_missing(method_name, *args)
    if METHODS.include? method_name
      write({ :method => method_name })
      poll
    else
      super
    end
  end

private

  def write(message)
    serial.puts(message.to_json)
    sleep(0.5) # TODO: make this async
  end

  # Validate a message from Arduino
  def validate(message)
    return true
    # return message['type'] && message['id'] && message['state'] && message['millis']
  end

end
