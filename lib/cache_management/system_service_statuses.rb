module CacheManagement

  # This cache is based on a shared DB Table with SAAS.
  # Whenever this is flushed even SAAS one should be flushed
  class SystemServiceStatuses

    include Util::ResultHelper

    # Fetch from db
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch

      data_to_cache = Memcache.get_set_memcached(get_cache_key, get_cache_expiry) do
        data_to_cache = {saas_api_available: 1, company_api_available: 1}
        db_records = SystemServiceStatus.all
        db_records.each do |db_record|
          if (db_record.status == GlobalConstant::SystemServiceStatus.running_status)
            is_available = 1
          else
            is_available = 0
          end
          case db_record.name
            when GlobalConstant::SystemServiceStatus.saas_api_name
              data_to_cache[:saas_api_available] = is_available
            when GlobalConstant::SystemServiceStatus.company_api_name
              data_to_cache[:company_api_available] = is_available
            else
              fail "unsupported #{db_record.name}"
          end
        end
        data_to_cache
      end

      success_with_data(data_to_cache)

    end

    # clear cache
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def clear
      Memcache.delete(get_cache_key)
      success
    end

    private

    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [MemcacheKey]
    #
    def memcache_key_object
      @m_k_o ||= MemcacheKey.new('system.services_statuses')
    end

    # Fetch cache key
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [String]
    #
    def get_cache_key
      memcache_key_object.key_template % {}
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