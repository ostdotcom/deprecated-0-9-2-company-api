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
    def fetch_from_db(cache_miss_ids)

      data_to_cache = {}

      record = CurrencyConversionRate.where(["status = ? AND quote_currency = ?", 1, 1]).order('timestamp desc').first

      data_to_cache[1] = {}
      data_to_cache[1][record.base_currency] = {}
      data_to_cache[1][record.base_currency][record.quote_currency] = record.conversion_rate.to_s

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