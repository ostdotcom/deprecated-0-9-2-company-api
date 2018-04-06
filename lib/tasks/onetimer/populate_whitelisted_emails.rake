namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:populate_whitelisted_emails'

  task :populate_whitelisted_emails => :environment do

    require 'csv'

    CSV.foreach('emails.csv', :headers => false) do |row|
      email = row[0]
      next unless Util::CommonValidator.is_valid_email?(email)
      email = email.strip.downcase
      WhitelistedEmail.create!(email: email)
    end

  end

end
