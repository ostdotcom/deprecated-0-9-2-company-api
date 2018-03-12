module CacheManagement

  class ClientTokenTransactionCount < CacheManagement::Base

    private

    # Fetch from db
    #
    # * Author: Puneet
    # * Date: 10/03/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_from_db(cache_miss_ids)

      data_to_cache = {}

      # Avoiding doing a count(*) query here as this could be a big table
      ClientTokenTransaction.where(client_token_id: cache_miss_ids).
          select(:id, :client_token_id).find_in_batches(batch_size: 1000) do |batched_db_records|

        batched_db_records.each do |db_record|

          data_to_cache[db_record.client_token_id] ||= 0
          data_to_cache[db_record.client_token_id] += 1

        end

      end

      success_with_data(data_to_cache)

    end

    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [MemcacheKey]
    #
    def memcache_key_object
      @m_k_o ||= MemcacheKey.new('mics.ost_fiat_conversion_factors')
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
      # It uses shared cache key between company api and saas.
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

  end

end