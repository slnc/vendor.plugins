# necesario para que el Return-Path se ponga bien.
class ActionMailer::Base
  def perform_delivery_sendmail(mail)
    IO.popen("#{sendmail_settings[:location]} -f #{mail.from} -r #{@return_path} #{sendmail_settings[:arguments]}","w+") do |sm|
      sm.print(mail.encoded.gsub(/\r/, ''))
      sm.flush
    end
  end
end