# Handles communicating status to the outside world via text, phone call, HTTP.
class Comms

  class << self
    attr_reader :twilio_config, :mandrill_config, :sms_to, :sms_from, :email_to, :email_from
  end

  # Accepts a Setting record and extracts whatever columns are needed
  def self.setup(config)
    @twilio_config = [config.twilio_account_sid, config.twilio_auth_token]
    @sms_to = config.contact_numbers
    @sms_from = config.from_phone_number
    @mandrill_config = [config.mandrill_api_key]
    @email_to = config.contact_emails.split(',')
    @email_from = config.from_email
  end

  def self.twilio_client
    @twilio_client ||= Twilio::REST::Client.new(*twilio_config)
  end

  def self.mandrill_client
    @mandrill_client ||= Mandrill::API.new(*mandrill_config)
  end

  # Sends a text message to everyone who wants to be notified
  def self.sms(message)
    twilio_client.account.messages.create({
      :to   => sms_to,
      :from => sms_from,
      :body => message
    })
  rescue Twilio::REST::RequestError => e
    $logger.error "Problem sending text message #{e.message}\n#{e.backtrace}"
  end

  def self.email(subject, message)
    to = email_to.collect { |e| { :email => e } }
    mandrill_client.messages.send({ :subject => subject, :text => message, :from_email => email_from, :to => to }, false)
      $logger.debug("Sending email to #{email_to}:\n\n#{message}")
  end

end
