module CacheManagement

  class ClientTokenSecure < CacheManagement::Base

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

      company_managed_address_id_client_id_map, cache_data = {}, {}

      ::ClientToken.where(id: cache_miss_ids).select(:id, :uuid, :erc20_address, :company_managed_addresses_id).
          all.each do |client_token|

        cache_data[client_token.id] = {
          uuid: client_token.uuid,
          erc20_address: client_token.erc20_address
        }

        if client_token.company_managed_addresses_id.present?
          company_managed_address_id_client_id_map[client_token.company_managed_addresses_id] = client_token.id
        end

      end

      if company_managed_address_id_client_id_map.present?

        CompanyManagedAddress.where(id: company_managed_address_id_client_id_map.keys).
            select(:ethereum_address, :id).all.each do |object|

          #TODO: ADD code to decrypt ethereum_address
          # either fire API call to SAA which has logic to decrypt or duplicate logic here
          cache_data[company_managed_address_id_client_id_map[object.id]][:reserve_address] = '0xddA2cB099235F657b77b8ABf055725c88cbc6112' #object.ethereum_address

        end

      end

      success_with_data(cache_data)

    end

    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [MemcacheKey]
    #
    def memcache_key_object
      @m_k_o ||= MemcacheKey.new('client.token_details_s')
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