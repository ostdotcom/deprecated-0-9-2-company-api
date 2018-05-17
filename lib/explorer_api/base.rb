module ExplorerApi

  class Base

    include Util::ResultHelper

    require 'http'
    require 'openssl'

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 19/02/2018
    # * Reviewed By:
    #
    # @return [SaasApi::Base]
    #
    def initialize
      @timeouts = {
        write: 5,
        connect: 5,
        read: 5
      }
    end

    private

    # Send Api request
    #
    # * Author: Pankaj
    # * Date: 19/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def send_request_of_type(request_type, path)
      begin

        request_path = GlobalConstant::ExplorerApi.base_url + path

        # It overrides verification of SSL certificates
        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

        parameterized_token = {token: get_jwt_token({url: "/#{path}",
                                                        request_time: Time.now.to_i})}

        case request_type
          when 'get'
            response = HTTP.timeout(@timeouts)
                         .get(request_path, params: parameterized_token, ssl_context: ssl_context)
          when 'post'
            response = HTTP.timeout(@timeouts)
                         .post(request_path, json: parameterized_token, ssl_context: ssl_context)
          else
            return error_with_data(
                'l_ea_b_1',
                 'something_went_wrong',
                 GlobalConstant::ErrorAction.default,
                {request_type: request_type}
            )
        end

        case response.status
          when 200
            parsed_response = Oj.load(response.body.to_s)
            if parsed_response['success']
              return success_with_data(HashWithIndifferentAccess.new(parsed_response['data']))
            else
              # web3_js_error = true is required because when API is down or any exception is raised or response is not 200
              # front end doesn't need to see invalid ethereum address
              return error_with_data(
                  parsed_response['err']['code']+':st(l_ea_b_2)',
                 'something_went_wrong',
                 GlobalConstant::ErrorAction.default,
                 {web3_js_error: true, status: response.status, msg: parsed_response['err']['msg']}
              )
            end
          else
            return error_with_data(
                'l_ea_b_3',
                'something_went_wrong',
                GlobalConstant::ErrorAction.default
            )
        end
      rescue => e
        return error_with_data(
            'l_ea_b_4',
            'something_went_wrong',
            GlobalConstant::ErrorAction.default,
            {message: e.message}
        )
      end
    end

    # Create encrypted Token
    #
    # * Author: Pankaj
    # * Date: 19/02/2018
    # * Reviewed By:
    #
    # @params [Hash] data
    #
    # @return [String] Encoded token
    #
    def get_jwt_token(data)
      payload = {data: data}
      secret_key = GlobalConstant::ExplorerApi.secret_key

      JWT.encode(payload, secret_key, 'HS256')
    end

  end

end