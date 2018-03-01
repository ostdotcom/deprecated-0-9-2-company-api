module CacheManagement

  class CriticalChainInteractionStatus < CacheManagement::Base

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
      
      f_dependent_entity_records = {}

      # Fetch rows with ids in  cache_miss_ids
      db_records = CriticalChainInteractionLog.where(id: cache_miss_ids).
          select(:id, :parent_id, :activity_type, :status, :request_params).all

      db_records.each do |db_object|

        next if GlobalConstant::CriticalChainInteractions.activity_types_to_mark_pending.exclude?(db_object.activity_type)

        f_dependent_entity_records[db_object.id] ||= {}
        f_dependent_entity_records[db_object.id][db_object.activity_type] = db_object
        
      end

      # Fetch rows with parent_ids in cache_miss_ids
      CriticalChainInteractionLog.where(parent_id: cache_miss_ids).
          select(:id, :parent_id, :activity_type, :status, :request_params).all.each do |db_object|

        next if dependent_activity_types.exclude?(db_object.activity_type)

        f_dependent_entity_records[db_object.parent_id] ||= {}
        f_dependent_entity_records[db_object.parent_id][db_object.activity_type] = db_object

      end

      cache_data = {}

      db_records.each do |db_record|

        # if this records had a parent id we ignore it as it should be an independent id to be given dara
        next if db_record.parent_id.present?

        dependent_entity_records = f_dependent_entity_records[db_record.id]
        mandatory_activity_kinds = mandatory_steps_for_type(db_record)
        
        formatted_data_for_id = []
        mandatory_activity_kinds.each do |activity_kind|
          activity_kind_data = dependent_entity_records[activity_kind]
          if activity_kind_data.blank?
            # this step has not been initiated yet
            formatted_data_for_id << {
                status: GlobalConstant::CriticalChainInteractions.queued_status,
                display_text: get_default_text_for_activity_kind(activity_kind),
                activity_kind: activity_kind
            }
          else
            formatted_data_for_id << {
              status: activity_kind_data.status,
              display_text: activity_type_display_text(activity_kind_data),
              activity_kind: activity_kind
            }
          end
        end

        cache_data[db_record.id] = formatted_data_for_id

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
      @m_k_o ||= MemcacheKey.new('client.tx_status_details')
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

    # for an activity_type returns an array of activity_types which are mandatory steps
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @param [CriticalChainInteractionLog] db_record
    #
    # @return [Array]
    #
    def mandatory_steps_for_type(db_record)
      case db_record.activity_type
        # NOTE: These types should be ordered. First step which needs to be executed should be first
        when GlobalConstant::CriticalChainInteractions.propose_bt_activity_type
          steps = [GlobalConstant::CriticalChainInteractions.propose_bt_activity_type]
          if is_bt_to_be_minted?(db_record)
            steps << GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type
          end
          if is_st_prime_to_be_minted?(db_record)
            steps << GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
          end
          if db_record.request_params[:airdrop_user_list_type].present?
            steps << GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type
          end
        when GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type
          steps = [GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type]
          if is_bt_to_be_minted?(db_record)
            steps << GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type
          end
          if is_st_prime_to_be_minted?(db_record)
            steps << GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
          end
        when GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type
          steps = [GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type]
        else
          fail "unsupported activity_type: #{activity_type}"
      end
      steps
    end

    # From a db object get display text
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @param [CriticalChainInteractionLog] db_object
    #
    # @return [String]
    #
    def activity_type_display_text(db_object)
      request_params = db_object.request_params
      case db_object.activity_type
        when GlobalConstant::CriticalChainInteractions.propose_bt_activity_type
          'Registering Branded Token'
        when GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type
          "Staking #{request_params[:to_stake_amount]} OST to mint #{request_params[:bt_to_mint]} #{request_params[:token_symbol]}"
        when GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
          "Staking #{request_params[:to_stake_amount]} for Transaction Fees"
        when GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type
          "AirDrop #{request_params[:airdrop_amount]}#{request_params[:token_symbol]} to users is In-Process."
        when GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type
          "Verifying Transfer of #{request_params[:to_stake_amount]} to Staker."
        else
          fail "unsupported activity_type: #{db_object.activity_type}"
      end
    end

    # For activity_type
    #
    # * Author: Puneet
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @param [String] activity_type
    #
    # @return [String]
    #
    def get_default_text_for_activity_kind(activity_type)
      case activity_type
        when GlobalConstant::CriticalChainInteractions.propose_bt_activity_type
          'Registering Branded Token'
        when GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type
          'Staking OST to mint BT'
        when GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
          'Staking OST for Transaction Fees'
        when GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type
          'AirDrop In Process'
        when GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type
          "Verifying Transfer to Staker."
        else
          fail "unsupported activity_type: #{activity_type}"
      end
    end

    def is_st_prime_to_be_minted?(db_record)
      db_record.request_params[:st_prime_to_mint].present? && BigDecimal.new(db_record.request_params[:st_prime_to_mint]) > 0
    end

    def is_bt_to_be_minted?(db_record)
      db_record.request_params[:bt_to_mint].present? && BigDecimal.new(db_record.request_params[:bt_to_mint]) > 0
    end

    def dependent_activity_types
      buffer = GlobalConstant::CriticalChainInteractions.activity_types_to_mark_pending.dup
      buffer += [
          GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type,
          GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
      ]
    end

  end

end