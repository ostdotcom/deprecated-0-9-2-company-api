# frozen_string_literal: true
module GlobalConstant

  class ManagementApi

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

    def self.secret_key
      #TODO - move this to env vars
      '1somethingsarebetterkeptinenvironemntvariables'
    end

  end

end
