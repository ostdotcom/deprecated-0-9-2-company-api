class FetchOstFiatConversionFactors

  class << self

    #
    # * Author: Puneet
    # * Date: 02/02/2018
    # * Reviewed By:
    #
    def perform

      Memcache.get_set_memcached(memcache_key, memcache_expiry) do
        {
          usd: 0.008 #TODO: fix this
        }
      end

    end

    private

    def memcache_key_obj
      @m_k_obj ||= MemcacheKey.new('mics.ost_fiat_conversion_factors')
    end

    def memcache_key
      memcache_key_obj.key_template
    end

    def memcache_expiry
      memcache_key_obj.expiry
    end

  end

end