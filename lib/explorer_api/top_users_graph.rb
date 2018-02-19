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
    #
    # @return [Result::Base]
    #
    def perform(params)
      send_request_of_type(
          'get',
          (GlobalConstant::ExplorerApi.top_users_graph_path % [GlobalConstant::ExplorerApi.chain_id, params[:token_erc_addr]])
      )
    end

  end

end
