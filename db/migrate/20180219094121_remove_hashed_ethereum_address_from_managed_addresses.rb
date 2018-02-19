class RemoveHashedEthereumAddressFromManagedAddresses < DbMigrationConnection

  def change
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      remove_column :managed_addresses, :hashed_ethereum_address

      add_index :managed_addresses, [:ethereum_address], name: 'uniq_ethereum_address', unique: true

    end
  end

end
