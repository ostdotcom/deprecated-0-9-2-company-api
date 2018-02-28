# Configure God send email settings
God::Contacts::Email.defaults do |d|
  d.from_email = 'god@ost.com'
  d.from_name = 'Simpletoken God'
  d.delivery_method = :sendmail
  d.sendmail_path = '/usr/sbin/sendmail'
  d.sendmail_args = '-i -t'
end

# Configure the contact to be notified from god
God.contact(:email) do |c|
  c.name  = 'Simpletoken Api Team'
  c.to_email = 'bala@ost.com,sunil@ost.com,kedar@ost.com,alpesh@ost.com,pankaj@ost.com,aman@ost.com'
  c.group = 'developers'
end
