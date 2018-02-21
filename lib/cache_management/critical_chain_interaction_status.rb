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

      db_records = CriticalChainInteractionLog.where(id: cache_miss_ids).
          or(CriticalChainInteractionLog.where(parent_id: cache_miss_ids))

      aggregared_db_records = {}
      primary_id_mandatory_steps_map = {}

      db_records.each do |db_record|

        if db_record.parent_id.present?
          id_to_index = db_record.parent_id
        else
          id_to_index = db_record.id
          primary_id_mandatory_steps_map[id_to_index] = mandatory_steps_for_type(db_record.activity_type)
        end

        aggregared_db_records[id_to_index] ||= {}

        aggregared_db_records[id_to_index][db_record.activity_type] = db_record

      end

      formatted_data = {}

      aggregared_db_records.each do |primary_id, data|
        mandatory_activity_kinds = primary_id_mandatory_steps_map[primary_id]
        formatted_data_for_id = []
        mandatory_activity_kinds.each do |activity_kind|
          activity_kind_data = data[activity_kind]
          if activity_kind_data.blank?
            # this step has not been initiated yet
            formatted_data_for_id << {
                status: GlobalConstant::CriticalChainInteractions.queued_status,
                display_text: get_default_text_for_activity_kind(activity_kind)
            }
          else
            formatted_data_for_id << {
              status: activity_kind_data.status,
              display_text: activity_type_display_text(activity_kind_data)
            }
          end
        end
        formatted_data[primary_id] = formatted_data_for_id
      end

      success_with_data(formatted_data)

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
    # @param [String] activity_type
    #
    # @return [Array]
    #
    def mandatory_steps_for_type(activity_type)
      case activity_type
        # NOTE: These types should be ordered. First step which needs to be executed should be first
        when GlobalConstant::CriticalChainInteractions.propose_bt_activity_type
          [
            GlobalConstant::CriticalChainInteractions.propose_bt_activity_type,
            GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type,
            GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
          ]
        when GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type
          [
            GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type,
            GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
          ]
        else
          fail "unsupported activity_type: #{activity_type}"
      end
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
        #TODO: Using input params and all change language
        when GlobalConstant::CriticalChainInteractions.propose_bt_activity_type
          'Registering Branded Token'
        when GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type
          "Staking #{request_params[:to_stake_amount]} OST to mint #{request_params[:bt_to_mint]} #{request_params[:token_symbol]}"
        when GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
          "Staking #{request_params[:to_stake_amount]} for Transaction Fees"
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
        else
          fail "unsupported activity_type: #{activity_type}"
      end
    end

  end

end