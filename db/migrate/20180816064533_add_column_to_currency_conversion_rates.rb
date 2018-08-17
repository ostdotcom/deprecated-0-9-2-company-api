class AddColumnToCurrencyConversionRates < DbMigrationConnection
  def up

    client = Client.first
    client_id = client.id

    r = SaasApi::OnBoarding::FetchChainInteractionParams.new.perform({client_id: client_id})
    fail 'chain id not found' unless r.success?

    utility_chain_id = r.data['utility_chain_id']

    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do

      add_column :currency_conversion_rates, :chain_id, :integer, after: :id, null: false, default: utility_chain_id

    end

  end

  def down

    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do

      remove_column :currency_conversion_rates, :chain_id

    end

  end

end

