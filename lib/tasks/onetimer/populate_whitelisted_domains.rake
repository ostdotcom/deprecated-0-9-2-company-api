namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:populate_whitelisted_domains'

  task :populate_whitelisted_domains => :environment do

    require 'csv'

    existing_domians_map = {}
    WhitelistedDomain.select(:domain).all.each do |db_record|
      existing_domians_map[db_record.domain.strip.downcase] = 1
    end

    CSV.foreach('domains.csv', :headers => false) do |row|
      domain = row[0]
      domain = domain.strip.downcase
      next if existing_domians_map[domain] == 1
      WhitelistedDomain.create!(domain: domain)
    end

  end

end
