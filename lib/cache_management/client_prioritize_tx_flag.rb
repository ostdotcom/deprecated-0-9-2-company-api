module CacheManagement

  class ClientPrioritizeTxFlag < CacheManagement::Base

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

      cache_miss_ids.each do |client_token_id|

        db_records = ClientTokenTransaction.where(client_token_id: client_token_id).
            select(:id, :client_token_id).limit(3).all

        proritize_company_to_user = db_records.length < 3

        data_to_cache[client_token_id] = {company_to_user: proritize_company_to_user}

      end

      cache_miss_ids.each do |client_token_id|
        data_to_cache[client_token_id] ||= {company_to_user: true}
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
      @m_k_o ||= MemcacheKey.new('client.prioritize_tx_flag')
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

  end

end