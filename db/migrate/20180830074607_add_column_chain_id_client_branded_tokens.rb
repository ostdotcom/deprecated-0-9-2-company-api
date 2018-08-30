class AddColumnChainIdClientBrandedTokens < DbMigrationConnection
  def up

    client = Client.first
    if client.blank?

      addChainIdWithoutDefaultValue

    else

      client_id = client.id

      r = SaasApi::OnBoarding::FetchChainInteractionParams.new.perform({client_id: client_id})

      if !r.success? || r.data['utility_chain_id'].blank?

        addChainIdWithoutDefaultValue

      else

        addChainIdWithDefaultValue(r.data['utility_chain_id'])

      end

    end

  end

  def down
    remove_column :client_branded_tokens, :chain_id
  end

  def addChainIdWithoutDefaultValue
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      add_column :client_branded_tokens, :chain_id, :integer, after: :id, :null => false
    end
  end

  def addChainIdWithDefaultValue(chainIdDefaultValue)
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      add_column :client_branded_tokens, :chain_id, :integer, after: :id, :null => false, default: chainIdDefaultValue
    end
  end

end
