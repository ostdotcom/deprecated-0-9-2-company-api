module Economy

  class AirdropToUsers < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 23/02/2018
    # * Reviewed By:
    #
    # @params [Integer] client_id (mandatory) - client id
    # @params [Integer] client_token_id (mandatory) - client token id
    # @params [Integer] airdrop_amount (mandatory) - Amount to airdrop in Branded token base unit.
    # @params [String] airdrop_list_type (mandatory) - List type of users to airdrop eg: all or new
    # @params [Integer] parent_critical_log_id (Optional) - Parent critical log id, if it starts from stake and mint
    #
    # @return [Economy::AirdropToUsers]
    #
    def initialize(params)

      super

      @client_token_id = @params[:client_token_id]
      @client_id = @params[:client_id]
      @airdrop_amount = @params[:airdrop_amount]
      @airdrop_list_type = @params[:airdrop_list_type]
      @parent_critical_log_id = @params[:parent_critical_log_id]

      @chain_interaction = nil
      @api_response_data = {}

    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 23/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = validate_airdrop_done
      return r unless r.success?

      r = make_saas_call
      return r unless r.success?

      insert_initial_db_record

      enqueue_job

      success_with_data(
          pending_critical_interactions:
              {GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type => @chain_interaction.id}
      )
    end

    private

    # Validate and sanitize
    #
    # * Author: Pankaj
    # * Date: 23/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      validation_errors = {}

      if @airdrop_amount.present?
        @airdrop_amount = BigDecimal.new(@airdrop_amount)
        validation_errors[:airdrop_amount] = 'Airdrop amount should be > 0' if @airdrop_amount <=0
      else
        validation_errors[:airdrop_amount] = 'Airdrop amount can not be blank'
      end

      return error_with_data(
          'e_adu_1',
          'Params Error',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          validation_errors
      ) if validation_errors.present?

      r = validate
      return r unless r.success?

      @client = @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

      return error_with_data(
          'e_adu_2',
          'Invalid Client.',
          'Invalid Client.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client.blank?

      @client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]

      return error_with_data(
          'e_adu_3',
          'Invalid Client Token.',
          'Invalid Client Token.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_token.blank? or @client_token[:client_id] != @client_id

      success

    end

    # Validate AirDrop has been pending or done before.
    #
    # * Author: Pankaj
    # * Date: 23/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_airdrop_done
      client_chain_interactions = CriticalChainInteractionLog.of_activity_type(GlobalConstant::CriticalChainInteractions.
          airdrop_users_activity_type).where(client_id: @client_id).group_by(&:status)

      # No requests present
      return success if client_chain_interactions.blank?

      # Pending requests present then send error
      return error_with_data(
          'e_adu_3',
          'Pending AirDrop requests.',
          'Pending AirDrop requests.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if (client_chain_interactions.keys & [GlobalConstant::CriticalChainInteractions.queued_status,
                                              GlobalConstant::CriticalChainInteractions.pending_status]).present?

      # TODO: Do we have to apply any other checks

      success
    end

    # Create new record
    #
    # * Author: Pankaj
    # * Date: 23/02/2018
    # * Reviewed By:
    #
    # Sets @chain_interaction
    #
    # @return [Result::Base]
    #
    def insert_initial_db_record
      @chain_interaction = CriticalChainInteractionLog.create!(client_id: @client_id,
                                                               client_token_id: @client_token_id,
                                                               activity_type: GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type,
                                                               chain_type: GlobalConstant::CriticalChainInteractions.utility_chain_type,
                                                               status: GlobalConstant::CriticalChainInteractions.pending_status,
                                                               request_params: {
                                                                   airdrop_amount: @airdrop_amount,
                                                                   token_symbol: @client_token[:symbol],
                                                                   users_list_to_airdrop: @airdrop_list_type
                                                               },
                                                               parent_id: @parent_critical_log_id,
                                                               transaction_uuid: @api_response_data["airdrop_uuid"]
      )
    end

    # Make Saas Api call
    #
    # * Author: Pankaj
    # * Date: 23/02/2018
    # * Reviewed By:
    #
    #
    # @return [Result::Base]
    #
    def make_saas_call

      result = CacheManagement::ClientApiCredentials.new([@client_id]).fetch[@client_id]
      return error_with_data(
          'e_adu_4',
          "Invalid client.",
          'Something Went Wrong.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if result.blank?

      # Create OST Sdk Obj
      credentials = OSTSdk::Util::APICredentials.new(result[:api_key], result[:api_secret])
      @ost_sdk_obj = OSTSdk::Saas::Users.new(GlobalConstant::Base.sub_env, credentials)

      service_response = @ost_sdk_obj.airdrop_tokens(token_symbol: @client_token[:symbol], amount: @airdrop_amount,
                                                     list_type: @airdrop_list_type)

      return error_with_data(
          'e_adu_5',
           service_response.error_message,
          'Something Went Wrong.',
          GlobalConstant::ErrorAction.default,
          {},
          service_response.error_data || {}
      ) unless service_response.success?

      @api_response_data = service_response.data

      success

    end

    # Enqueue job
    #
    # * Author: Pankaj
    # * Date: 22/02/2018
    # * Reviewed By:
    #
    def enqueue_job

      BgJob.enqueue(
          Airdrop::GetAirdropTransactionStatusJob,
          {
              critical_log_id: @chain_interaction.id
          },
          {
              wait: 10.seconds
          }
      )

    end

  end

end

