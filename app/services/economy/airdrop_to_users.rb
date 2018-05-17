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
    # @params [Integer] amount (mandatory) - Amount to airdrop in Branded token base unit.
    # @params [String] airdropped (Optional) - List type of users to airdrop eg: all or new
    # @params [Integer] parent_critical_log_id (Optional) - Parent critical log id, if it starts from stake and mint
    #
    # @return [Economy::AirdropToUsers]
    #
    def initialize(params)

      super

      @client_token_id = @params[:client_token_id]
      @client_id = @params[:client_id]
      @amount = @params[:amount]
      @airdropped = @params[:airdropped]
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

      # if r.success?
      #   @chain_interaction.transaction_uuid = @api_response_data["airdrop_uuid"]
      #   @chain_interaction.status = GlobalConstant::CriticalChainInteractions.pending_status
      #   @chain_interaction.save
      # else
      #   @chain_interaction.status = GlobalConstant::CriticalChainInteractions.failed_status
      #   @chain_interaction.response_data = r.to_hash
      #   @chain_interaction.save
      #   return r
      # end

      # enqueue_job

      puts @api_response_data

      success_with_data(
        pending_critical_interactions: {
          GlobalConstant::CriticalChainInteractions.airdrop_users_activity_type => @api_response_data['critical_chain_interaction_log_id']
        }
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

      if @amount.present?

        @amount = BigDecimal.new(@amount)

        if @amount <=0
          return validation_error(
              'e_adu_1',
              'invalid_api_params',
              ['invalid_amount'],
              GlobalConstant::ErrorAction.default
          )
        end

      end

      r = validate
      return r unless r.success?

      @client = @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

      return validation_error(
          'e_adu_2',
          'invalid_api_params',
          ['invalid_client_id'],
          GlobalConstant::ErrorAction.default
      ) if @client.blank?

      @client_token = CacheManagement::ClientToken.new([@client_token_id]).fetch[@client_token_id]

      return error_with_data(
          'e_adu_3',
          'unauthorized_for_other_client',
          GlobalConstant::ErrorAction.default
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
          'pending_grant_requests',
          GlobalConstant::ErrorAction.default
      ) if (client_chain_interactions.keys & [GlobalConstant::CriticalChainInteractions.queued_status,
                                              GlobalConstant::CriticalChainInteractions.pending_status]).present?

      # TODO: Do we have to apply any other checks

      success

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

      s_params = {
          client_id: @client_id,
          token_symbol: @client_token[:symbol],
          amount: @amount,
          client_token_id: @client_token_id
      }

      s_params[:airdropped] = @airdropped if @airdropped.present? && @airdropped != 'all'
      service_response = SaasApi::KitStartAirdrop.new.perform(s_params)

      return service_response unless service_response.success?

      @api_response_data = service_response.data

      success

    end

  end

end

