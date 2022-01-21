class ContactMessageService
  def self.create(contact_message:, actor:)
    if contact_message.valid?
      BaseMailer.delay.contact_message(
        contact_message.name,
        contact_message.email,
        contact_message.subject,
        contact_message.message
      )
    else
      raise "failed to send a contact message. name: #{contact_message.name}, #{contact_message.email}, #{contact_message.subject}"
    end
  end
end
