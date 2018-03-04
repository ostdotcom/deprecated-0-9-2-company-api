# frozen_string_literal: true
module GlobalConstant

  class ExplorerApi

    def self.base_url
      GlobalConstant::Base.explorer_api['base_url']
    end

    def self.secret_key
      GlobalConstant::Base.explorer_api['secret']
    end

    def self.transactions_type_graph_path
      "chain-id/%s/tokenDetails/%s/graph/transactionsByType/%s"
    end

    def self.number_of_transactions_graph_path
      "chain-id/%s/tokenDetails/%s/graph/numberOfTransactions/%s"
    end

    def self.top_users_graph_path
      "chain-id/%s/tokenDetails/%s/topUsers"
    end

    def self.chain_id
      200
    end

  end

end
