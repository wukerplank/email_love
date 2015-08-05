class MessageHandler

  attr_accessor :gmail

  def initialize(possible_recipients)
    @possible_recipients = possible_recipients
  end

  def handle_message(message)
    if forward_to = extract_recipient(message)
      if html_part = extract_html_part(message)
        puts "Found an HTML part :-)"
        forward_with_html_part(forward_to, message.subject, html_part.body.decoded)
      else
        puts "Found no HTML part :-("
        forward_with_original(forward_to, message.subject, message.message)
      end
    end
  end

  private

  def extract_recipient(message)
    recipient = message.to.first

    forward_to = recipient.split('@').first.split('+').last.downcase

    if @possible_recipients.keys.include? forward_to
      puts "Forwarding to #{@possible_recipients[forward_to]}"
      return @possible_recipients[forward_to]
    else
      puts "User not found or not given (#{forward_to})"
      return false
    end
  end

  def extract_html_part(message)
    return message.html_part
  end

  def forward_with_html_part(forward_to, subject, html_part)
    attachment = temporary_file_from(html_part, 'html')

    gmail.deliver do
      to forward_to
      subject "[Extracted HTML 😀] #{subject}"
      html_part do
        content_type 'text/html; charset=UTF-8'
        body File.read('./templates/html_attachment.html')
      end

      add_file attachment
    end
  end

  def forward_with_original(forward_to, subject, message)
    attachment = temporary_file_from(message.to_s, 'eml')

    gmail.deliver do
      to forward_to
      subject "[Extracted HTML 😞] #{subject}"
      html_part do
        content_type 'text/html; charset=UTF-8'
        body File.read('./templates/no_html_attachment.html')
      end

      add_file attachment
    end

  end

  def temporary_file_from(data, extension)
    filename = "/tmp/#{Digest::MD5.hexdigest(data.to_s)}.#{extension}"

    File.open(filename, 'wb') do |file|
      file.write(data.to_s)
    end

    return filename
  end

end
