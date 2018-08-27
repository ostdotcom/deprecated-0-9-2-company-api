module ClientManagement

  class GetTestOst < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) - Client Id to get Test Ost
    # @param [Integer] client_token_id (mandatory) - Client Token Id to get Test Ost.
    # @param [String] eth_address (Optional) - eth address for first time in client set up flow
    #
    # @return [ClientManagement::GetTestOst]
    #
    def initialize(params)

      super

      @client_id = @params[:client_id]
      @client_token_id = @params[:client_token_id]
      @eth_address = @params[:eth_address]

      @client = nil
      @client_token = nil
      @client_chain_interaction = nil
      @chain_interaction_params = nil

    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      # Set up Eth address if its given in input
      if @eth_address.present?
        r = ClientManagement::SetupEthAddress.new(client_id: @client_id, eth_address: @eth_address).perform
        return r unless r.success?
      else
        r = fetch_client_eth_address
        return r unless r.success?
      end

      # Validate, whether OST can be given or not
      r = validate_ost_given
      return r unless r.success?

      r = fetch_chain_interaction_params
      return r unless r.success?

      insert_db

      r = make_saas_api_call
      return r

    end

    private

    # Validate and sanitize
    #
    # * Author: Pankaj
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      return r unless r.success?

      @client = @client = CacheManagement::Client.new([@client_id]).fetch[@client_id]

      return validation_error(
          'cm_gto_1',
          'invalid_api_params',
          ['invalid_client_id'],
          GlobalConstant::ErrorAction.default
      ) if @client.blank?

      @client_token = ClientToken.where(id: @client_token_id).first

      return validation_error(
          'cm_gto_1',
          'invalid_api_params',
          ['invalid_client_id'],
          GlobalConstant::ErrorAction.default
      ) if @client_token.blank? or @client_token.client_id != @client_id

      success

    end

    # Validate, Whether OST is given to client before or not.
    #
    # * Author: Pankaj
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_ost_given

      client_chain_interactions = CriticalChainInteractionLog.of_activity_type(GlobalConstant::CriticalChainInteractions.
          request_ost_activity_type).where(client_id: @client_id).order('created_at DESC').group_by(&:status)

      if client_chain_interactions.blank?
        # Client had never requested
        @amount = GlobalConstant::ClientAddress.default_first_time_ost_grant_amount
        return success
      end

      # Pending requests present then send error
      return error_with_data(
          'cm_gto_3',
          'pending_grant_requests',
          GlobalConstant::ErrorAction.default
      ) if client_chain_interactions.keys.include?(GlobalConstant::CriticalChainInteractions.pending_status)

      # If client had requested before we would give him lesser OST
      @amount = GlobalConstant::ClientAddress.default_recurring_ost_grant_amount

      # Check for last processed request time
      processed_records = client_chain_interactions[GlobalConstant::CriticalChainInteractions.processed_status]
      return success if processed_records.blank?

      # Check last processed record created_at

      grant_again_after = (Rails.env.production? && GlobalConstant::Base.sub_env == 'main') ? 10.year : 1.day

      return error_with_data(
          'cm_gto_4',
          'grant_limit_breached',
          GlobalConstant::ErrorAction.default
      ) if (Time.now - grant_again_after).to_i < processed_records.first.created_at.to_i

      success

    end

    # Fetch chain interaction params
    #
    # * Author: Puneet
    # * Date: 12/08/2018
    # * Reviewed By:
    #
    # Sets @chain_interaction_params
    #
    # @return [Result::Base]
    #
    def fetch_chain_interaction_params
      r = SaasApi::OnBoarding::FetchChainInteractionParams.new.perform({client_id: @client_id})
      return r unless r.success?
      @chain_interaction_params = r.data
      r
    end

    # Create new record
    #
    # * Author: Pankaj
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # Sets @chain_interaction
    #
    # @return [Result::Base]
    #
    def insert_db
      @chain_interaction = CriticalChainInteractionLog.create!(
          client_id: @client_id, client_token_id: @client_token_id,
          chain_id: @chain_interaction_params['value_chain_id'],
          activity_type: GlobalConstant::CriticalChainInteractions.request_ost_activity_type,
          chain_type: GlobalConstant::CriticalChainInteractions.value_chain_type,
          status: GlobalConstant::CriticalChainInteractions.pending_status,
          request_params: {amount: @amount}
      )
    end

    # Make SAAS API call
    #
    # * Author: Pankaj
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def make_saas_api_call

      r = SaasApi::OnBoarding::GrantTestOst.new.perform(
          client_id: @client_id,
          ethereum_address: @eth_address,
          amount: @amount
      )

      unless r.success?
        @chain_interaction.status = GlobalConstant::CriticalChainInteractions.failed_status
        @chain_interaction.response_data = r.to_hash
        @chain_interaction.save!
        return r
      end

      @chain_interaction.transaction_uuid = r.data[:transaction_uuid]
      @chain_interaction.transaction_hash = r.data[:transaction_hash]
      @chain_interaction.status = GlobalConstant::CriticalChainInteractions.processed_status
      @chain_interaction.save!

      @client_token.send("set_#{GlobalConstant::ClientToken.received_test_ost_setup_step}")
      @client_token.save!

      CacheManagement::ClientToken.new([@client_token.id]).clear

      r

    end

    # Fetch Eth Address of client
    #
    # * Author: Pankaj
    # * Date: 16/02/2018
    # * Reviewed By:
    #
    # Sets @eth_address
    #
    # @return [Result::Base]
    #
    def fetch_client_eth_address

      client_address_data = CacheManagement::ClientAddress.new([@client_id]).fetch[@client_id]

      return error_with_data(
          'cm_gto_5',
          'invalid_client_id',
          GlobalConstant::ErrorAction.default
      ) if client_address_data.blank? || client_address_data[:ethereum_address_d].blank?

      @eth_address = client_address_data[:ethereum_address_d]

      success

    end

  end

end
