module CacheManagement

  #TODO: This cache does not have info_salt. Should we add it here or in seperat cache or keep querying from db ?
  class Client < CacheManagement::Base

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

      client_default_token_id_map = ::ClientToken.where(client_id: cache_miss_ids, status: GlobalConstant::ClientToken.active_status).
          select(:id, :client_id).order('id ASC').all.inject({}) do |map, client_token|

        map[client_token.client_id] = client_token.id
        map

      end

      client_manager_user_ids_map = ::ClientManager.
          where(client_id: cache_miss_ids, status: GlobalConstant::ClientManager.active_status).
          select(:id, :client_id, :user_id).all.inject({}) do |map, client_manager|

        map[client_manager.client_id] ||= []
        map[client_manager.client_id] << client_manager.user_id
        map

      end

      aggregated_data = ::Client.where(id: cache_miss_ids).select(:id, :status).all.inject({}) do |clients_data, client|
        clients_data[client.id] = {
          id: client.id,
          status: client.status,
          default_token_id: client_default_token_id_map[client.id],
          manager_user_ids: client_manager_user_ids_map[client.id]
        }
        clients_data
      end

      aggregated_data

    end

    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [MemcacheKey]
    #
    def memcache_key_object
      @m_k_o ||= MemcacheKey.new('client.details')
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