module CacheManagement

  class OSTPricePoints < CacheManagement::Base

    private

    # Fetch from db
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_from_db(cache_miss_uc_chain_ids)

      data_to_cache = {}

      cache_miss_uc_chain_ids.each do |cache_miss_uc_chain_id|
        record = CurrencyConversionRate.
            where(["chain_id = ? AND status = ? AND quote_currency = ?", cache_miss_uc_chain_id, 1, 1]).
            order('timestamp desc').first
        data_to_cache[cache_miss_uc_chain_id] = {}
        data_to_cache[cache_miss_uc_chain_id][record.base_currency] = {}
        data_to_cache[cache_miss_uc_chain_id][record.base_currency][record.quote_currency] = record.conversion_rate.to_s
      end

      Rails.logger.info(data_to_cache)

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
    def get_cache_key(chain_id)
      # It uses shared cache key between company api and saas.
      memcache_key_object.key_template % @options.merge(chain_id: chain_id)
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