class WhitelistedEmail < EstablishCompanyUserDbConnection

  after_commit :flush_cache

  def flush_cache
    CacheManagement::WhitelistedEmails.new().clear
  end

end