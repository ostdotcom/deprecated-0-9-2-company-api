# frozen_string_literal: true
module GlobalConstant

  class SaasApi

    def self.base_url
      GlobalConstant::Base.company_restful_api[:endpoint]
    end

    def self.display_only_base_url
      GlobalConstant::Base.company_restful_api[:display_endpoint]
    end

    def self.secret_key
      GlobalConstant::Base.company_restful_api[:secret_key]
    end

    def self.start_on_boarding_api_path
      'internal/on-boarding/start'
    end

    def self.start_stake
      'internal/stake/start'
    end

    def self.grant_test_ost_path
      'internal/on-boarding/grant-test-ost'
    end

    def self.grant_eth_path
      'internal/on-boarding/grant-eth'
    end

    def self.setup_token_path
      'internal/on-boarding/setup-token'
    end

    def self.edit_token_path
      'internal/on-boarding/edit-token'
    end

    def self.get_chain_interaction_params_path
      'internal/on-boarding/get-chain-interaction-params'
    end

    def self.create_dummy_users_path
      'internal/on-boarding/create-dummy-users'
    end

    def self.get_staked_amount
      'internal/stake/get-staked-amount'
    end

    def self.simulate_transaction
      'internal/simulator/create-transaction'
    end

    def self.fetch_transaction_details
      'internal/simulator/get-transaction-details'
    end

    def self.fetch_cliient_stats
      'internal/client/fetch-stats'
    end

    def self.get_user_details_path
      'internal/client-users/get-details'
    end

    def self.get_addresses_by_uuids
      'internal/client-users/get-addresses-by-uuid'
    end

    def self.get_balances_path
      'internal/on-boarding/fetch-balances'
    end

    def self.kit_start_airdrop_path
      'internal/client-users/airdrop/kit-drop'
    end

  end

end
