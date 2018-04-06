namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:populate_whitelisted_emails'

  task :populate_whitelisted_emails => :environment do

    require 'csv'

    existing_emails_map = {}
    WhitelistedEmail.select(:email).all.each do |db_record|
      existing_emails_map[db_record.email.strip.downcase] = 1
    end

    CSV.foreach('emails.csv', :headers => false) do |row|
      email = row[0]
      next unless Util::CommonValidator.is_valid_email?(email)
      email = email.strip.downcase
      next if existing_emails_map[email] == 1
      WhitelistedEmail.create!(email: email)
    end

  end

end
