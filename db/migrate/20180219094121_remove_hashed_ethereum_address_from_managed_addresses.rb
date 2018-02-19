class RemoveHashedEthereumAddressFromManagedAddresses < DbMigrationConnection

  def change
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      remove_column :managed_addresses, :hashed_ethereum_address

    end
  end

end
