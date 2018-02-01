class ClientSetupActivityLog < EstablishCompanyClientEconomyDbConnection

  enum activity_type: {
      GlobalConstant::ClientEconomyActivityLog.request_ost_activty_type => 1,
      GlobalConstant::ClientEconomyActivityLog.transfer_to_staker_activty_type => 2
  }

  enum chain_type: {
      GlobalConstant::ClientEconomyActivityLog.value_chain_type => 1,
      GlobalConstant::ClientEconomyActivityLog.utility_chain_type => 2
  }

  enum status: {
      GlobalConstant::ClientEconomyActivityLog.pending_status => 1,
      GlobalConstant::ClientEconomyActivityLog.processed_status => 2,
      GlobalConstant::ClientEconomyActivityLog.failed_status => 3
  }

  serialize :debug_data, Hash

end
