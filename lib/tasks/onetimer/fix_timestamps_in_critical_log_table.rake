namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:fix_timestamps_in_critical_log_table'

  task :fix_timestamps_in_critical_log_table => :environment do

    CriticalChainInteractionLogTemp.find_in_batches(batch_size: 100) do |batched_objs|
      batched_objs.each do |object|
        puts "#{object.id}"
        CriticalChainInteractionLog.where(id: object.id).
            update_all(created_at: object.created_at, updated_at: object.updated_at)
      end
    end

    Rails.cache.clear

  end

end
