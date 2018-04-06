namespace :one_timers do

  desc 'Usage -> rake RAILS_ENV=development one_timers:populate_critical_chain_interaction_log'

  task :populate_critical_chain_interaction_log => :environment do

    CriticalChainInteractionLogTemp.find_in_batches(batch_size: 100) do |batched_objs|
      batched_objs.each do |object|
        CriticalChainInteractionLog.create(
          id: object.id,
          client_id: object.client_id,
          client_token_id: object.client_token_id,
          parent_id: object.parent_id,
          activity_type: object.activity_type,
          chain_type: object.chain_type,
          transaction_uuid: object.transaction_uuid,
          transaction_hash: object.transaction_hash,
          request_params: object.request_params,
          response_data: object.response_data,
          status: object.status
        )
      end
    end

  end

end
