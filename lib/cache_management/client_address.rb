module CacheManagement

  class ClientAddress < CacheManagement::Base

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
      data_from_cache.each do |client_id, client_address_data|

        next if client_address_data.blank?

        r = encryptor_obj.decrypt(client_address_data[:ethereum_address_e])

        if r.success?
          client_address_data.delete(:ethereum_address_e)
          client_address_data[:ethereum_address_d] = r.data[:plaintext]
        else
          data_from_cache[client_id] = {}
        end

      end

      data_from_cache

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

      db_records = ::ClientAddress.where(
          client_id: cache_miss_ids, status: GlobalConstant::ClientAddress.active_status
      )

      aggregated_cache_data = {}

      db_records.each do |db_record|

        r = Aws::Kms.new('api_key','user').decrypt(db_record.address_salt)
        next unless r.success?

        r = LocalCipher.new(r.data[:plaintext]).decrypt(db_record.ethereum_address)
        next unless r.success?

        encrypt_rsp = encryptor_obj.encrypt(r.data[:plaintext])
        next unless encrypt_rsp.success?

        aggregated_cache_data[db_record.client_id] = {
          ethereum_address_e: encrypt_rsp.data[:ciphertext_blob],
          hashed_ethereum_address: db_record.hashed_ethereum_address
        }

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
      @m_k_o ||= MemcacheKey.new('client.address')
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