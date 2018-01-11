class ClientManager < EstablishCompanyClientDbConnection

  enum status: {
    GlobalConstant::ClientManager.active_status => 1,
    GlobalConstant::ClientManager.inactive_status => 2
  }

end
