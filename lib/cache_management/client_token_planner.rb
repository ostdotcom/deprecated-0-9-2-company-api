module CacheManagement

  class ClientTokenPlanner < CacheManagement::Base

    # Fetch from cache and for cache misses call fetch_from_db
    # 1. If initial_airdrop_in_wei is set in DB return
    # 2. Else using some vars compute what could be the initial_airdrop_in_wei
    # Note: Data for 2 can not be cached as OST values change frequently and thats a art of the calculation
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

      ost_to_fiat = BigDecimal.new(FetchOraclePricePoints.perform[:ost][:usd])
      default_ost_grant_amount = GlobalConstant::ClientAddress.default_ost_grant_amount
      default_initial_users = GlobalConstant::Client.default_initial_users
      max_initial_bt_airdrop_amount = GlobalConstant::Client.max_initial_bt_airdrop_amount
      buffer_mint_factor_over_airdrop = GlobalConstant::Client.buffer_mint_factor_over_airdrop

      data_from_cache.each do |client_token_id, token_planner_data|

        next if token_planner_data.blank? || token_planner_data[:initial_airdrop_in_wei].present?

        bt_to_fiat = BigDecimal.new(token_planner_data[:token_worth_in_usd])

        ost_to_bt = ost_to_fiat / bt_to_fiat

        max_initial_ost_airdrop_amount = max_initial_bt_airdrop_amount / ost_to_bt

        required_ost_to_airdrop_max = max_initial_ost_airdrop_amount * default_initial_users * buffer_mint_factor_over_airdrop

        if required_ost_to_airdrop_max <= default_ost_grant_amount
          airdrop_bt_amount = max_initial_bt_airdrop_amount
        else
          airdrop_bt_amount = (default_ost_grant_amount * ost_to_bt / (default_initial_users * buffer_mint_factor_over_airdrop)).round
        end

        token_planner_data[:initial_airdrop] = airdrop_bt_amount.to_s
        token_planner_data[:initial_airdrop_in_wei] = Util::Converter.to_wei_value(airdrop_bt_amount).to_s

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

      data_to_cache = ::ClientTokenPlanner.where(client_token_id: cache_miss_ids).all.inject({}) do |cache_data, client_token|

        cache_data[client_token.client_token_id] = client_token.formated_cache_data

        cache_data

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
      @m_k_o ||= MemcacheKey.new('client.token_planner_details')
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