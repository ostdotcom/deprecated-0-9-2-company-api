namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:sanitize_old_emails_and_domains'

  task :sanitize_old_emails_and_domains => :environment do

    WhitelistedEmail.all.each do |email_row|
      email = email_row.email
      if email != email.downcase.strip
        puts "Non-sanitized email: #{email}"
        sanitized_email = email.downcase.strip
        puts "Sanitized email: #{sanitized_email}"
        email_row.email = sanitized_email
        email_row.save!
      end
    end

    WhitelistedDomain.all.each do |domain_row|
      domain = domain_row.domain
      if domain != domain.downcase.strip
        puts "Non-sanitized domain: #{domain}"
        sanitized_domain = domain.downcase.strip
        puts "Sanitized domain: #{sanitized_domain}"
        domain_row.domain = sanitized_domain
        domain_row.save!
      end
      
    end

    Rails.cache.clear

  end

end
