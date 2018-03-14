class ClientTokenTransaction < EstablishCompanyClientEconomyDbConnection

  after_commit :flush_cache

  def flush_cache

    prioritize_tx_flags = CacheManagement::ClientPrioritizeTxFlag.new([client_token_id]).fetch[client_token_id]

    # if this flag is true, no need to flush. as this will not change
    if prioritize_tx_flags.blank? || prioritize_tx_flags[:company_to_user]
      CacheManagement::ClientPrioritizeTxFlag.new([client_token_id]).clear
    end

  end

end