
namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:rotate_client_api_credentials'

  task :rotate_client_api_credentials => :environment do

    failed_clients = {}

    Client.where(status: GlobalConstant::Client.active_status).select(:id).all.each do |client|

      r = RotateClientApiCredentials.new(client_id: client.id).perform
      unless r.success?
        failed_clients[client.id] = r.data
      end

    end

    if failed_clients.present?
      puts "Failed clients logs: #{failed_clients}"
    end

    Rails.cache.clear

  end

end
