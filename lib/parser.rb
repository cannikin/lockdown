# Generic parser that others should inherit from. Handles logging events and
# saving a reference to `settings` which is the Sinatra settingslication
class Parser

  attr_reader :settings

  def initialize(settings)
    @settings = settings
  end

private

  def log_event(event)
    Event.create :type => event['event'],
                 :data => event['data'].to_json,
                 :created_at => Time.now
  end

  # Sends a text message to everyone who wants to be notified
  def send_text(message)
    settings.twilio_client.account.messages.create({
      :to => '+17606725123',
      :from => '+17605374466',
      :body => message
    })
  end

end
