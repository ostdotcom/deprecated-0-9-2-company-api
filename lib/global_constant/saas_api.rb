# frozen_string_literal: true
module GlobalConstant

  class SaasApi

    def self.base_url
      #TODO - move this to env vars
      'http://127.0.0.1:3000/'
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

    def self.setup_token_path
      'on-boarding/setup-token'
    end

    def self.approve_for_stake_api_path
      'stake/approve'
    end

    def self.get_approve_status_for_stake_api_path
      'stake/approval-status'
    end

    def self.start_stake
      'stake/start'
    end

    def self.secret_key
      #TODO - move this to env vars
      '1somethingsarebetterkeptinenvironemntvariables'
    end

  end

end
