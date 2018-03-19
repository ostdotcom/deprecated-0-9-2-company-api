class AlterManagedAddressIndexes < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      remove_index :managed_addresses, name: 'uk_1'
      add_index :managed_addresses, [:uuid], name: 'uk_1', unique: true
      add_index :managed_addresses, [:client_id], name: 'i_1', unique: false
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      remove_index :managed_addresses, name: 'uk_1'
      remove_index :managed_addresses, name: 'i_1'
    end
  end

end
