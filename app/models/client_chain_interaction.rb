class ClientChainInteraction < EstablishCompanyClientEconomyDbConnection

  enum activity_type: {
      GlobalConstant::ClientChainInteraction.request_ost_activty_type => 1,
      GlobalConstant::ClientChainInteraction.transfer_to_staker_activty_type => 2
  }

  enum chain_type: {
      GlobalConstant::ClientChainInteraction.value_chain_type => 1,
      GlobalConstant::ClientChainInteraction.utility_chain_type => 2
  }

  enum status: {
      GlobalConstant::ClientChainInteraction.pending_status => 1,
      GlobalConstant::ClientChainInteraction.processed_status => 2,
      GlobalConstant::ClientChainInteraction.failed_status => 3
  }

  serialize :debug_data, Hash

end