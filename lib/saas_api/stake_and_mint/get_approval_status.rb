# module SaasApi
#
#   module StakeAndMint
#
#     class GetApprovalStatus < SaasApi::Base
#
#       # Initialize
#       #
#       # * Author: Kedar
#       # * Date: 29/01/2018
#       # * Reviewed By:
#       #
#       # @return [SaasApi::StakeAndMint::GetApprovalStatus]
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
#       # @param [String] transaction_hash (mandatory) - transaction hash of the approval transaction
#       #
#       # @return [Result::Base]
#       #
#       def perform(params = {})
#         send_request_of_type(
#           'get',
#           GlobalConstant::SaasApi.get_approve_status_for_stake_api_path,
#           params
#         )
#       end
#
#     end
#
#   end
#
# end
