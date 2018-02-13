module ClientManagement

  class GetTestOst < ServicesBase

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) - Client Id to get Test Ost
    # @param [Float] requested_amount (mandatory) - Amount of Test OST requested by client.
    # @param [String] eth_address (Optional) - eth address for first time in client set up flow
    #
    # @return [ClientManagement::GetTestOst]
    #
    def initialize(params)

      super

      @client_id = @params[:client_id]
      @client_token_id = @params[:client_token_id]
      @amount = @params[:requested_amount] || 500
      @eth_address = @params[:eth_address]

      @client = nil
      @client_token = nil
      @client_chain_interaction = nil

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

      # Set up Eth address if its present
      if @eth_address.present?
        r = ClientManagement::SetupEthAddress.new(client_id: @client_id, eth_address: @eth_address).perform
        return r unless r.success?
      else
        fetch_client_reserve_address
      end

      # Validate, whether OST can be given or not
      r = validate_ost_given
      return r unless r.success?

      insert_db

      r = make_saas_api_call
      return r

      # TODO:: Make transaction UUID and transaction hash table.

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

      @client = Client.where(id: @client_id).first

      return error_with_data(
          'cm_gto_1',
          'Invalid Client.',
          'Invalid Client.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client.blank?

      @client_token = ClientToken.where(id: @client_token_id).first

      return error_with_data(
          'cm_gto_2',
          'Invalid Client Token.',
          'Invalid Client Token.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_token.blank? or @client_token.client_id != @client.id

      success

    end

    # Validate, Whether OST is given to client before or not.
    # TODO:: Put duration checks id required. For now one day check is kept.
    #
    # * Author: Pankaj
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_ost_given
      client_chain_interactions = ClientChainInteraction.of_activity_type(GlobalConstant::ClientChainInteraction.
          request_ost_activity_type).where(client_token_id: @client_token_id).order('created_at DESC').group_by(&:status)

      # No requests present
      return success if client_chain_interactions.blank?

      # Pending requests present then send error
      return error_with_data(
          'cm_gto_3',
          'Pending Test OST requests.',
          'Pending Test OST requests.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if client_chain_interactions.keys.include?(GlobalConstant::ClientChainInteraction.pending_status)

      # Check for last processed request time
      processed_records = client_chain_interactions[GlobalConstant::ClientChainInteraction.processed_status]
      return success if processed_records.blank?

      # Check last processed record created_at is less than 1 day
      return error_with_data(
          'cm_gto_4',
          'Test OST cannot be given before 24 hours from last given.',
          'Test OST cannot be given before 24 hours from last given.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if (Time.now - 1.day).to_i < processed_records.first.created_at.to_i

      success

    end

    # Create new record
    #
    # * Author: Pankaj
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # Sets @client_chain_interaction
    #
    # @return [Result::Base]
    #
    def insert_db
      @client_chain_interaction = ClientChainInteraction.create!(client_id: @client_id, client_token_id: @client_token_id,
                                    activity_type: GlobalConstant::ClientChainInteraction.request_ost_activity_type,
                                    chain_type: GlobalConstant::ClientChainInteraction.value_chain_type,
                                    status: GlobalConstant::ClientChainInteraction.pending_status,
                                    debug_data: {amount: @amount})
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
      r = SaasApi::OnBoarding::GrantTestOst.new.perform(ethereum_address: @eth_address, amount: @amount)
      return r unless r.success?
    end

    def fetch_client_reserve_address
      @client_token_s = CacheManagement::ClientTokenSecure.new([@client_token_id]).fetch[@client_token_id]
      @eth_address = @client_token_s[:reserve_address]
    end


  end

end
