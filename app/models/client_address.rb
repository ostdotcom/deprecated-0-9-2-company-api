class ClientAddress < EstablishCompanyClientEconomyDbConnection

  enum status: {
      GlobalConstant::ClientAddress.active_status => 1,
      GlobalConstant::ClientAddress.inactive_status => 2
  }

end
