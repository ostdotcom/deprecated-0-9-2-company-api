module CacheManagement

  class ClientApiCredentials < CacheManagement::Base

    # Fetch from cache and for cache misses call fetch_from_db
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Hash]
    #
    def fetch

      data_from_cache = super

      data_from_cache = data_from_cache.deep_dup ## Deep DUP is important here

      # as cache has local cypher encrypted value of API Secret, we would need to decrypt it before sending it out
      data_from_cache.each do |client_id, api_credentials|

        next if api_credentials.blank?

        r = encryptor_obj.decrypt(api_credentials[:api_secret])

        if r.success?
          api_credentials[:api_secret] = r.data[:plaintext]
        else
          data_from_cache[client_id] = {}
        end

      end

      data_from_cache

    end

    # Clear cache
    #
    # * Author: Pankaj
    # * Date: 03/03/2018
    # * Reviewed By:
    #
    def clear

      set_id_to_cache_key_map

      cache_response = fetch
      @id_to_cache_key_map.each do |id, key|
        Memcache.delete(key)
        Memcache.delete("ca_sa_shared_de_sa_cs_#{cache_response[id][:api_key]}")
      end

      nil

    end

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

      aggregated_cache_data = {}

      cache_miss_ids.each do |client_id|

        get_credentials_rsp = ClientManagement::GetClientApiCredentials.new(client_id: client_id).perform
        return get_credentials_rsp unless get_credentials_rsp.success?

        api_credentials = get_credentials_rsp.data[:api_credentials]

        encrypt_rsp = encryptor_obj.encrypt(api_credentials[:api_secret])
        return encrypt_rsp unless encrypt_rsp.success?

        cache_data = {
          api_key: api_credentials[:api_key],
          api_secret: encrypt_rsp.data[:ciphertext_blob]
        }

        aggregated_cache_data[client_id] = cache_data

      end

      success_with_data(aggregated_cache_data)

    end

    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [MemcacheKey]
    #
    def memcache_key_object
      @m_k_o ||= MemcacheKey.new('client.api_credentials')
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

    # object which encrypts / decrypts
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [LocalCipher]
    #
    def encryptor_obj
      @e_obj ||= LocalCipher.new(GlobalConstant::SecretEncryptor.cache_data_sha_key)
    end

  end

end