# Handles motion events

require 'parser'

class HttpParser < Parser

  def parse(params, options={})
    options = { :log => true }.merge(options)
    log_event({:event => params[:event], :data => params}) if options[:log]
    output = []

    case params[:event]
    when 'motion'
      behavior = Behavior.where(:mode => settings.mode.to_s).first
      output << { :event => 'motion', :data => { :location => params[:location] }}
      if behavior.text_on_motion
        begin
          Comms.sms "Motion detected: #{params[:location]} http://air.local:4567"
        rescue => e
          logger.error "Problem sending text message #{e.message}\n#{e.backgtrace}"
        end
      end
    else

    end

    return output
  end

end
