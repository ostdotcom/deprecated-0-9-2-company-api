class RemoveChainGethProvidersTable < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSaasConfigDbConnection) do

      drop_table :chain_geth_providers

    end

  end

  def down

    run_migration_for_db(EstablishSaasConfigDbConnection) do

    end

  end

end

