# Handles communicating status to the outside world via text, phone call, HTTP.

class Comms

  def self.twilio_client
    @twilio_client ||= Twilio::REST::Client.new('ACe05457154ff9016641e1063a8d9ecf86', '764e4d23a040f4efa49557d023678d9a')
  end

  # Sends a text message to everyone who wants to be notified
  def self.sms(message)
    twilio_client.account.messages.create({
      :to => Setting.first.contact_numbers,
      :from => Setting.first.from_phone_number,
      :body => message
    })
  end

end
