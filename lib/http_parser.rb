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
        Comms.sms "Motion detected: #{params[:location].upcase}. System in #{settings.mode.upcase} mode. http://lockdown.local:4567?key=#{settings.config.access_key}"
      end
    else
      output << { :error => "Unknown event: #{params[:event]}" }
    end

    return output
  end

end
