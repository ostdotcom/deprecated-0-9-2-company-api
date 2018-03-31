# class Airdrop::SetopsAirdropStatusJob < ApplicationJob
#
#   include Util::ResultHelper
#
#   queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue
#
#   # Perform
#   #
#   # * Author: Kedar
#   # * Date: 29/01/2018
#   # * Reviewed By: Sunil
#   #
#   # @param [Integer] critical_log_id (mandatory) - id of ClientChainInteraction
#   # @param [Integer] parent_id (mandatory) - parent id of next tasks in chain
#   #
#   def perform(params)
#
#     init_params(params)
#
#     r = validate
#     return r unless r.success?
#
#     r = setops_airdrop_deploy_status
#     return unless r.success?
#
#     if @critical_chain_interaction_log.is_processed?
#
#       set_worker
#
#       set_price_oracle
#
#       set_accepted_margin
#
#     else
#
#       enqueue_self
#
#     end
#
#     success
#
#   end
#
#   private
#
#   # init params
#   #
#   # * Author: Kedar
#   # * Date: 29/01/2018
#   # * Reviewed By: Sunil
#   #
#   def init_params(params)
#     @critical_log_id = params[:critical_log_id]
#     @parent_id = params[:parent_id]
#
#     @critical_chain_interaction_log = nil
#     @transaction_hash = nil
#     @client_id = nil
#
#   end
#
#   # Validate params
#   #
#   # * Author: Puneet
#   # * Date: 01/02/2018
#   # * Reviewed By: Sunil
#   #
#   # Sets @critical_chain_interaction_log, @transaction_hash , @client_token
#   #
#   # @return [Result::Base]
#   #
#   def validate
#
#     @critical_chain_interaction_log = CriticalChainInteractionLog.where(id: @critical_log_id).first
#
#     return error_with_data(
#       'j_s_gasj_1',
#       'Critical chain interation log id not found.',
#       'Critical chain interation log id not found.',
#       GlobalConstant::ErrorAction.default,
#       {}
#     ) if @critical_chain_interaction_log.blank?
#
#     @transaction_hash = @critical_chain_interaction_log.transaction_hash
#     @client_token = ClientToken.where(id: @critical_chain_interaction_log.client_token_id).first
#     @client_id = @critical_chain_interaction_log.client_id
#     success
#   end
#
#   # Get Airdrop deploy Status
#   #
#   # * Author: Alpesh
#   # * Date: 21/02/2018
#   # * Reviewed By:
#   #
#   # @return [Result::Base]
#   #
#   def setops_airdrop_deploy_status
#     # Initial transfer transaction is done
#     return success if @critical_chain_interaction_log.is_processed?
#
#     r = SaasApi::StakeAndMint::GetReceipt.new.perform(
#       {
#         transaction_hash: @transaction_hash,
#         chain: GlobalConstant::CriticalChainInteractions.utility_chain_type
#       }
#     )
#
#     if @critical_chain_interaction_log.can_be_marked_timeout?
#       # Timeout
#       @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.timeout_status
#     elsif !r.success?
#       # failed - service failure
#       @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.failed_status
#     else
#       # r.data will be blank when transaction is yet not mined.
#       if r.data.present?
#         # processed
#         @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.processed_status
#       else
#         # pending
#         @critical_chain_interaction_log.status = GlobalConstant::CriticalChainInteractions.pending_status
#       end
#     end
#
#     @critical_chain_interaction_log.response_data = r.to_hash
#     @critical_chain_interaction_log.save!
#
#     if @critical_chain_interaction_log.is_pending? || @critical_chain_interaction_log.is_processed?
#       return success
#     else
#       return error_with_data(
#         'j_s_gasj_2',
#         'Transaction receipt failed.',
#         'Transaction receipt failed.',
#         GlobalConstant::ErrorAction.default,
#         {}
#       )
#     end
#
#     success
#   end
#
#   # Enqueue job
#   #
#   # * Author: alpesh
#   # * Date: 22/02/2018
#   # * Reviewed By:
#   #
#   def enqueue_self
#
#     BgJob.enqueue(
#       Airdrop::SetopsAirdropStatusJob,
#       {
#         critical_log_id: @critical_log_id,
#         parent_id: @parent_id
#       },
#       {
#         wait: 10.seconds
#       }
#     )
#
#   end
#
#   # set worker for a client
#   #
#   # * Author: alpesh
#   # * Date: 22/02/2018
#   # * Reviewed By:
#   #
#   def set_worker
#
#     request_params = {
#       client_id: @client_id,
#       token_symbol: @client_token.symbol,
#     }
#
#     saas_api_response = SaasApi::OnBoarding::SetWorker.new.perform(request_params)
#
#     process_set_worker_response(
#       request_params,
#       saas_api_response
#     )
#
#   end
#
#   # set price oracle in airdrop contract
#   #
#   # * Author: alpesh
#   # * Date: 22/02/2018
#   # * Reviewed By:
#   #
#   def set_price_oracle
#
#     request_params = {
#       client_id: @client_id,
#       token_symbol: @client_token.symbol,
#     }
#
#     saas_api_response = SaasApi::OnBoarding::SetPriceOracle.new.perform(request_params)
#
#     process_saas_response(
#       request_params,
#       saas_api_response,
#       GlobalConstant::CriticalChainInteractions.set_price_oracle_activity_type
#     )
#
#   end
#
#   # set accepted price fluctuation in airdrop contract
#   #
#   # * Author: alpesh
#   # * Date: 22/02/2018
#   # * Reviewed By:
#   #
#   def set_accepted_margin
#
#     request_params = {
#       client_id: @client_id,
#       token_symbol: @client_token.symbol,
#     }
#
#     saas_api_response = SaasApi::OnBoarding::SetAcceptedMargin.new.perform(request_params)
#
#     process_saas_response(
#       request_params,
#       saas_api_response,
#       GlobalConstant::CriticalChainInteractions.set_accepted_margin_activity_type
#     )
#
#   end
#
#
#   def process_saas_response(request_params, saas_api_response, activity_type)
#
#     if saas_api_response.success?
#       status = GlobalConstant::CriticalChainInteractions.pending_status
#       transaction_uuid = saas_api_response.data[:transaction_uuid]
#       transaction_hash = saas_api_response.data[:transaction_hash]
#     else
#       status = GlobalConstant::CriticalChainInteractions.failed_status
#     end
#
#     critical_log = CriticalChainInteractionLog.create!(
#       {
#         parent_id: @parent_id,
#         client_id: @client_id,
#         activity_type: activity_type,
#         client_token_id: @critical_chain_interaction_log.client_token_id,
#         chain_type: GlobalConstant::CriticalChainInteractions.utility_chain_type,
#         transaction_uuid: transaction_uuid,
#         transaction_hash: transaction_hash,
#         request_params: request_params,
#         response_data: saas_api_response.to_hash,
#         status: status
#       }
#     )
#
#     BgJob.enqueue(
#       Airdrop::GetAirdropSetupStatusJob,
#       {
#         critical_log_id: critical_log.id
#       },
#       {
#         wait: 10.seconds
#       }
#     ) if critical_log.is_pending?
#   end
#
#   # Process Set Worker response from Saas
#   #
#   # * Author: Pankaj
#   # * Date: 22/03/2018
#   # * Reviewed By:
#   #
#   def process_set_worker_response(request_params, saas_api_response)
#
#     if saas_api_response.success?
#       status = GlobalConstant::CriticalChainInteractions.pending_status
#     else
#       status = GlobalConstant::CriticalChainInteractions.failed_status
#     end
#
#     critical_log = CriticalChainInteractionLog.create!(
#         {
#             parent_id: @parent_id,
#             client_id: @client_id,
#             activity_type: GlobalConstant::CriticalChainInteractions.set_worker_activity_type,
#             client_token_id: @critical_chain_interaction_log.client_token_id,
#             chain_type: GlobalConstant::CriticalChainInteractions.utility_chain_type,
#             request_params: request_params,
#             response_data: saas_api_response.to_hash,
#             status: status
#         }
#     )
#
#     BgJob.enqueue(
#         Airdrop::AirdropWorkersSetupStatusJob,
#         {
#             critical_log_id: critical_log.id
#         },
#         {
#             wait: 10.seconds
#         }
#     ) if critical_log.is_pending?
#   end
#
# end
