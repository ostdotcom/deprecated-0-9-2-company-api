class AddColumnInManagedAddresses < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      add_column :managed_addresses, :properties, :tinyint, limit: 1, default: 0, after: :address_type
    end

  end

  def down

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      remove_column :managed_addresses, :properties
    end

  end
end
