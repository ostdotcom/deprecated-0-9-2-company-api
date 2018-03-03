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
    # @param [token_erc_addr] token_erc_addr (mandatory) - Client Token's ERC20 address
    # @param [client_id] client_id (mandatory) - Client Id to fetch data from saas
    #
    # @return [Result::Base]
    #
    def perform(params)
      response = send_request_of_type(
          'get',
          (GlobalConstant::ExplorerApi.top_users_graph_path % [GlobalConstant::ExplorerApi.chain_id, params[:token_erc_addr]])
      )
      result_type = response.data[:result_type]
      if response.data[result_type].present?
        users = response.data[result_type]
        ethereum_addresses = users.map{|x| x['address']}
        resp = SaasApi::FetchClientUsersDetails.new().perform({ethereum_addresses: ethereum_addresses,
                                                        client_id: params[:client_id]})
        return response if !resp.success? || resp.data.blank?

        new_response = []
        users.each do |user_data|
          eth_address = user_data['address']
          user_data['name'] = ''
          if resp.data.include?(eth_address)
            user_data['name'] = resp.data[eth_address]['name']
          end
          new_response << user_data
        end
        response.data[result_type] = new_response
      end

      response
    end

  end

end
