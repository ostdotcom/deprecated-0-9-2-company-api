# module SaasApi
# 
#   module OnBoarding
# 
#     class DeployAirdropContract < SaasApi::Base
# 
#       # Initialize
#       #
#       # * Author: Alpesh
#       # * Date: 21/02/2018
#       # * Reviewed By:
#       #
#       # @return [SaasApi::OnBoarding::DeployAirdropContract]
#       #
#       def initialize
#         super
#       end
# 
#       # Perform
#       #
#       # * Author: Alpesh
#       # * Date: 21/02/2018
#       # * Reviewed By:
#       #
#       # @param [String] token_symbol (mandatory) - token symbol
#       # @param [String] token_name (mandatory) - token name
#       # @param [Integer] client_id (mandatory) - client id
#       # @param [String] token_conversion_factor (mandatory) - token conversion rate
#       #
#       # @return [Result::Base]
#       #
#       def perform(params)
#         send_request_of_type(
#           'post',
#           GlobalConstant::SaasApi.deploy_airdrop_contract_path,
#           params
#         )
#       end
# 
#     end
# 
#   end
# 
# end
