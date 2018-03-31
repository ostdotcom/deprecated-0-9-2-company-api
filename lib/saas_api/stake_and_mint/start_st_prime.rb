# module SaasApi
#
#   module StakeAndMint
#
#     class StartStPrime < SaasApi::Base
#
#       # Initialize
#       #
#       # * Author: Kedar
#       # * Date: 29/01/2018
#       # * Reviewed By:
#       #
#       # @return [SaasApi::StakeAndMint::StartStPrime]
#       #
#       def initialize
#         super
#       end
#
#       # Perform
#       #
#       # * Author: Kedar
#       # * Date: 25/01/2018
#       # * Reviewed By:
#       #
#       # @param [String] beneficiary (mandatory) - eth address of the beneficiary
#       # @param [Number] to_stake_amount (mandatory) - this is the amount of OST to stake
#       # @param [String] uuid (mandatory) - uuid of the token
#
#       #
#       # @return [Result::Base]
#       #
#       def perform(params = {})
#         send_request_of_type(
#           'post',
#           GlobalConstant::SaasApi.start_stake_st_prime,
#           params
#         )
#       end
#
#     end
#
#   end
#
# end
