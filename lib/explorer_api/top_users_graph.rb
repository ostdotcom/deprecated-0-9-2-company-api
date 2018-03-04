module ExplorerApi

  class TopUsersGraph < ExplorerApi::Base

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 19/02/2018
    # * Reviewed By:
    #
    # @return [ExplorerApi::TopUsersGraph]
    #
    def initialize
      super
    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 19/02/2018
    # * Reviewed By:
    #
    # @param [client_token_id] client_token_id (mandatory) - Client Token Id
    # @param [client_id] client_id (mandatory) - Client Id to fetch data from saas
    #
    # @return [Result::Base]
    #
    def perform(params)
      client_token = CacheManagement::ClientTokenSecure.new([params[:client_token_id]]).fetch[params[:client_token_id]]
      response = send_request_of_type(
          'get',
          (GlobalConstant::ExplorerApi.top_users_graph_path % [GlobalConstant::ExplorerApi.chain_id, client_token[:token_erc20_address]])
      )
      result_type = response.data[:result_type]
      if response.data[result_type].present?
        users = response.data[result_type]
        ethereum_addresses = users.map{|x| x['address']}
        resp = SaasApi::FetchClientUsersDetails.new().perform({ethereum_addresses: ethereum_addresses,
                                                        client_id: params[:client_id]})
        return resp unless resp.success?

        new_response = []
        not_allowed_user_uuids = [client_token[:reserve_uuid], client_token[:worker_uuid], client_token[:airdrop_holder_uuid]]
        not_allowed_addresses = [client_token[:token_erc20_address], client_token[:airdrop_contract_address]]
        users.each do |user_data|
          eth_address = user_data['address']
          next if not_allowed_addresses.include?(eth_address)
          user_data['name'] = ''
          if resp.data.include?(eth_address)
            next if not_allowed_user_uuids.include?(resp.data[eth_address]['uuid'])
            user_data['name'] = resp.data[eth_address]['name']
            user_data['tokens'] = resp.data[eth_address]['token_balance']
            user_data['tokens_earned'] = (user_data['tokens_earned'].to_f + resp.data[eth_address]['total_airdropped_tokens'].to_f).to_s
            new_response << user_data
          end
        end
        response.data[result_type] = new_response[0...10]
      end

      response
    end

  end

end
