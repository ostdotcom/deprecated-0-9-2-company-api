module ExplorerApi

  class TransactionsTypeGraph < ExplorerApi::Base

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 19/02/2018
    # * Reviewed By:
    #
    # @return [ExplorerApi::TransactionsTypeGraph]
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
    # @param [graph_duration] graph_duration (mandatory) - Amount of time to fetch results for like (hour or day)
    #
    # @return [Result::Base]
    #
    def perform(params)
      send_request_of_type(
          'get',
          (GlobalConstant::ExplorerApi.transactions_type_graph_path % [GlobalConstant::ExplorerApi.chain_id, params[:token_erc_addr], params[:graph_duration]])
      )
    end

  end

end
