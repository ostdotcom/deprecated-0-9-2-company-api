class WhitelistedDomain < EstablishCompanyUserDbConnection

  after_commit :flush_cache

  def flush_cache
    CacheManagement::WhitelistedDomains.new().clear
  end

end