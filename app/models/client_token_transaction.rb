class ClientTokenTransaction < EstablishCompanyClientEconomyDbConnection

  after_commit :flush_cache

  def flush_cache
    CacheManagement::ClientTokenTransactionCount.new([client_token_id]).clear
  end

end