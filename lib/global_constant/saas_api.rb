# frozen_string_literal: true
module GlobalConstant

  class SaasApi

    def self.base_url
      GlobalConstant::Base.company_restful_api[:endpoint]
    end

    def self.secret_key
      GlobalConstant::Base.company_restful_api[:secret_key]
    end

    def self.propose_bt_api_path
      'on-boarding/propose-branded-token'
    end

    def self.get_registration_status_api_path
      'on-boarding/registration-status'
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

    def self.approve_for_stake_api_path
      'stake/approve'
    end

    def self.get_approve_status_for_stake_api_path
      'stake/approval-status'
    end

    def self.start_stake_bt
      'stake/start-bt'
    end

    def self.start_stake_st_prime
      'stake/start-st-prime'
    end

    def self.get_tx_receipt
      'stake/get-receipt'
    end

  end

end
