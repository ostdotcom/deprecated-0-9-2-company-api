module CacheManagement

  class PendingCriticalInteractionIds < CacheManagement::Base

    private

    # Fetch from db
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def fetch_from_db(cache_miss_ids)

      db_records = CriticalChainInteractionLog.where(client_token_id: cache_miss_ids).
          where('parent_id IS NULL').
          where(activity_type: GlobalConstant::CriticalChainInteractions.activity_types_to_mark_pending).all

      id_to_activity_type_map = {}

      db_records.each do |db_record|

        id_to_activity_type_map[db_record.id] = {
          activity_type: db_record.activity_type,
          client_token_id: db_record.client_token_id
        }

      end

      response_data = {}
      cache_data = CacheManagement::CriticalChainInteractionStatus.new(id_to_activity_type_map.keys).fetch
      cache_data.each do |id, data|
        next if data.blank?
        has_pending = false
        has_failed = false
        # check if any of these rows have failed or pending
        data.each do |row|
          if !has_pending
            has_pending = statuses_to_mark_pending.include?(row[:status])
          end
          if !has_failed
            has_failed = statuses_to_mark_failed.include?(row[:status])
          end
        end
        if has_pending && !has_failed
          buffer = id_to_activity_type_map[id]
          client_token_id = buffer[:client_token_id]
          response_data[client_token_id] ||= {}
          response_data[client_token_id][buffer[:activity_type]] = id
        end
      end

      success_with_data(response_data)

    end

    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [MemcacheKey]
    #
    def memcache_key_object
      @m_k_o ||= MemcacheKey.new('client.pending_critical_interaction_ids')
    end

    # Fetch cache key
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [String]
    #
    def get_cache_key(id)
      memcache_key_object.key_template % @options.merge(id: id)
    end

    # Fetch cache expiry (in seconds)
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Integer]
    #
    def get_cache_expiry
      memcache_key_object.expiry
    end

    def statuses_to_mark_failed
      [
          GlobalConstant::CriticalChainInteractions.failed_status,
          GlobalConstant::CriticalChainInteractions.timeout_status
      ]
    end

    def statuses_to_mark_pending
      [
          GlobalConstant::CriticalChainInteractions.queued_status,
          GlobalConstant::CriticalChainInteractions.pending_status
      ]
    end

  end

end
