class AddColumnToCurrencyConversionRates < DbMigrationConnection
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

    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do

      remove_column :currency_conversion_rates, :chain_id

    end

  end

  def addChainIdWithDefaultValue(defaultChainIdValue)
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      add_column :currency_conversion_rates, :chain_id, :integer, after: :id, null: false, default: defaultChainIdValue
    end
  end

  def addChainIdWithoutDefaultValue
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      add_column :currency_conversion_rates, :chain_id, :integer, after: :id, null: false
    end
  end

end

