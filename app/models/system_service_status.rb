class SystemServiceStatus < EstablishCompanySaasSharedDbConnection

  enum name: {
      GlobalConstant::SystemServiceStatus.saas_api_name => 1,
      GlobalConstant::SystemServiceStatus.company_api_name => 2
  }

  enum status: {
      GlobalConstant::SystemServiceStatus.running_status => 1,
      GlobalConstant::SystemServiceStatus.down_status => 2
  }

  after_commit :flush_cache

  def flush_cache
    CacheManagement::SystemServiceStatuses.new().clear
  end

end
