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

      data_to_cache = {}

      ::ClientToken.where(id: cache_miss_ids).
          select(:id, :client_id, :reserve_uuid, :token_erc20_address, :airdrop_contract_addr,
                 :airdrop_holder_addr_uuid).all.each do |client_token|

        buffer = client_token.formated_secure_cache_data

        uuids_for_fetching_addresses = []
        uuids_for_fetching_addresses << buffer[:reserve_uuid]
        uuids_for_fetching_addresses << buffer[:airdrop_holder_uuid]

        data_to_cache[client_token.id] = buffer

        resp = SaasApi::FetchClientAddressesByUuids.new().perform(
          uuids: uuids_for_fetching_addresses,
          client_id: buffer[:client_id]
        )

        next unless resp.success?

        user_addresses = resp.data['user_addresses']

        next if user_addresses.blank?

        reserve_address = user_addresses[buffer[:reserve_uuid]]
        buffer[:reserve_address] = reserve_address if reserve_address.present?

        airdrop_holder_address = user_addresses[buffer[:airdrop_holder_uuid]]
        buffer[:airdrop_holder_address] = airdrop_holder_address if airdrop_holder_address.present?

        data_to_cache[client_token.id] = buffer

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