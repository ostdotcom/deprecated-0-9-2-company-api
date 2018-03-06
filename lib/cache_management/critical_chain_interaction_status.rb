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
          select(:id, :client_token_id, :parent_id, :activity_type, :status, :request_params, :response_data).all

      client_token_ids = []

      db_records.each do |db_object|

        next if GlobalConstant::CriticalChainInteractions.activity_types_to_mark_pending.exclude?(db_object.activity_type)

        client_token_ids << db_object.client_token_id

        f_dependent_entity_records[db_object.id] ||= {}
        f_dependent_entity_records[db_object.id][db_object.activity_type] = db_object

      end

      client_token_ids.uniq!

      client_tokens = CacheManagement::ClientToken.new(client_token_ids).fetch

      # Fetch rows with parent_ids in cache_miss_ids
      CriticalChainInteractionLog.where(parent_id: cache_miss_ids).
          select(:id, :parent_id, :activity_type, :status, :request_params, :response_data).all.each do |db_object|

        next if dependent_activity_types.exclude?(db_object.activity_type)

        f_dependent_entity_records[db_object.parent_id] ||= {}
        f_dependent_entity_records[db_object.parent_id][db_object.activity_type] = db_object

      end

      cache_data = {}

      db_records.each do |db_record|

        # if this records had a parent id we ignore it as it should be an independent id to be given dara
        next if db_record.parent_id.present?

        client_token = client_tokens[db_record.client_token_id]

        dependent_entity_records = f_dependent_entity_records[db_record.id]
        mandatory_activity_kinds = mandatory_steps_for_type(db_record)

        formatted_data_for_id = []
        mandatory_activity_kinds.each do |activity_kind|
          activity_kind_data = dependent_entity_records[activity_kind]
          if activity_kind_data.blank?
            # this step has not been initiated yet
            formatted_data_for_id << {
                status: GlobalConstant::CriticalChainInteractions.queued_status,
                display_text: get_default_text_for_activity_kind(activity_kind, client_token),
                activity_kind: activity_kind
            }
          else
            formatted_data_for_id << {
                status: activity_kind_data.status,
                display_text: activity_type_display_text(activity_kind_data, client_token),
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
          steps = [
              GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type,
              GlobalConstant::CriticalChainInteractions.propose_bt_activity_type,
              GlobalConstant::CriticalChainInteractions.deploy_airdrop_activity_type,
              GlobalConstant::CriticalChainInteractions.setops_airdrop_activity_type,
              GlobalConstant::CriticalChainInteractions.set_worker_activity_type,
              GlobalConstant::CriticalChainInteractions.set_price_oracle_activity_type
          ]
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
    def activity_type_display_text(db_object, client_token)
      request_params = db_object.request_params
      response_data = db_object.response_data[:data]
      case db_object.activity_type
        when GlobalConstant::CriticalChainInteractions.propose_bt_activity_type
          if response_data.blank? || response_data['registration_status'].blank?
            "Proposing #{client_token[:symbol]} on OpenST Utility Blockchain"
          elsif response_data['registration_status']['is_registered_on_vc'] == 1
            "#{client_token[:symbol]} successfully registered"
          elsif response_data['registration_status']['is_registered_on_uc'] == 1
            "Registering #{client_token[:symbol]} on Ethereum"
          elsif response_data['registration_status']['is_proposal_done'] == 1
            "Registering #{client_token[:symbol]} on OpenST Utility Blockchain"
          end
        when GlobalConstant::CriticalChainInteractions.deploy_airdrop_activity_type
          case db_object.status
            when GlobalConstant::CriticalChainInteractions.processed_status
              'Airdrop smart contract successfuly deployed'
            else
              'Deploying your Airdrop contract'
          end
        when GlobalConstant::CriticalChainInteractions.setops_airdrop_activity_type
          case db_object.status
            when GlobalConstant::CriticalChainInteractions.processed_status
              'Operations address for airdrop smart contract successfuly configured'
            else
              'Configuring Operations address for Airdrop Contract'
          end
        when GlobalConstant::CriticalChainInteractions.set_worker_activity_type
          case db_object.status
            when GlobalConstant::CriticalChainInteractions.processed_status
              'Workers successfully authenticated to manage user accounts'
            else
              'Authenticating Workers to manage user accounts'
          end
        when GlobalConstant::CriticalChainInteractions.set_price_oracle_activity_type
          case db_object.status
            when GlobalConstant::CriticalChainInteractions.processed_status
              "$USD Price Oracle for #{client_token[:symbol]} successfully registered "
            else
              "Registering $USD Price Oracle for #{client_token[:symbol]}"
          end
        when GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type
          case db_object.status
            when GlobalConstant::CriticalChainInteractions.processed_status
              "OSTα successfully staked for minting #{client_token[:symbol]}"
            else
              "Staking OST alpha to mint #{client_token[:symbol]}"
          end
        when GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
          case db_object.status
            when GlobalConstant::CriticalChainInteractions.processed_status
              'OSTα successfuly staked as reserve for gas.'
            else
              'Staking OST alpha for GAS'
          end
        when GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type
          if response_data.blank? || response_data['steps_complete'].blank?
            'Verifying the list of users to receive airdrop'
          elsif response_data['steps_complete'].include?('allocation_done')
            'Airdrop successfully completed'
          elsif response_data['steps_complete'].include?('contract_approved')
            "Allocating #{client_token[:symbol]} to users"
          elsif response_data['steps_complete'].include?('tokens_transfered')
            'Budget holder to approving the Airdrop smart contract address'
          elsif response_data['steps_complete'].include?('users_identified')
            "Reserving #{client_token[:symbol]} for budget holder"
          end
        when GlobalConstant::CriticalChainInteractions.staker_initial_transfer_activity_type
          case db_object.status
            when GlobalConstant::CriticalChainInteractions.processed_status
              'Transfer to staker contract successfully verified'
            else
              'Verifying transfer to staker contract'
          end
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
    def get_default_text_for_activity_kind(activity_type, client_token)
      case activity_type
        when GlobalConstant::CriticalChainInteractions.propose_bt_activity_type
          "Registering #{client_token[:symbol]}"
        when GlobalConstant::CriticalChainInteractions.deploy_airdrop_activity_type
          'Deploying your Airdrop contract'
        when GlobalConstant::CriticalChainInteractions.setops_airdrop_activity_type
          'Configuring Operations address for Airdrop Contract'
        when GlobalConstant::CriticalChainInteractions.set_worker_activity_type
          'Authenticating Workers to manage user accounts'
        when GlobalConstant::CriticalChainInteractions.set_price_oracle_activity_type
          "Registering $USD Price Oracle for #{client_token[:symbol]}"
        when GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type
          "Staking OST alpha to mint #{client_token[:symbol]}"
        when GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
          'Staking OST alpha for GAS'
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
          GlobalConstant::CriticalChainInteractions.deploy_airdrop_activity_type,
          GlobalConstant::CriticalChainInteractions.set_worker_activity_type,
          GlobalConstant::CriticalChainInteractions.set_price_oracle_activity_type,
          GlobalConstant::CriticalChainInteractions.setops_airdrop_activity_type,
          GlobalConstant::CriticalChainInteractions.stake_bt_started_activity_type,
          GlobalConstant::CriticalChainInteractions.stake_st_prime_started_activity_type
      ]
    end

  end

end