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
      'on-boarding/start'
    end

    def self.start_stake
      'stake/start'
    end

    def self.grant_test_ost_path
      'on-boarding/grant-test-ost'
    end

    def self.grant_eth_path
      'on-boarding/grant-eth'
    end

    def self.setup_token_path
      'on-boarding/setup-token'
    end

    def self.edit_token_path
      'on-boarding/edit-token'
    end

    def self.get_chain_interaction_params_path
      'on-boarding/get-chain-interaction-params'
    end

    def self.create_dummy_users_path
      'on-boarding/create-dummy-users'
    end

    def self.get_staked_amount
      'stake/get-staked-amount'
    end

    def self.simulate_transaction
      'simulator/create-transaction'
    end

    def self.fetch_transaction_details
      'simulator/get-transaction-details'
    end

    def self.fetch_cliient_stats
      'client/fetch-stats'
    end

    def self.get_user_details_path
      'client-users/get-details'
    end

    def self.get_addresses_by_uuids
      'client-users/get-addresses-by-uuid'
    end

    def self.get_balances_path
      'on-boarding/fetch-balances'
    end

    # def self.get_tx_receipt
    #   'stake/get-receipt'
    # end
    #
    # def self.deploy_airdrop_contract_path
    #   'on-boarding/deploy-airdrop-contract'
    # end
    #
    # def self.get_registration_status_api_path
    #   'on-boarding/registration-status'
    # end
    #
    # def self.set_worker_path
    #   'on-boarding/set-worker'
    # end
    #
    # def self.fetch_worker_status_path
    #   'on-boarding/fetch-worker-status'
    # end
    #
    # def self.set_price_oracle_path
    #   'on-boarding/set-price-oracle'
    # end
    #
    # def self.set_accepted_margin_path
    #   'on-boarding/set-accepted-margin'
    # end
    #
    # def self.setops_airdrop_path
    #   'on-boarding/setops-airdrop'
    # end
    #
    # def self.approve_for_stake_api_path
    #   'stake/approve'
    # end
    #
    # def self.get_approve_status_for_stake_api_path
    #   'stake/approval-status'
    # end
    #
    # def self.start_stake_bt
    #   'stake/start-bt'
    # end
    #
    # def self.start_stake_st_prime
    #   'stake/start-st-prime'
    # end

  end

end
