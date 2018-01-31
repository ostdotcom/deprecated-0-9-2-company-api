class CreateCompanyManagedAddresses < DbMigrationConnection
  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      create_table :company_managed_addresses do |t|
        t.column :ethereum_address, :blob #encrypted
        t.column :hashed_ethereum_address, :string
        t.column :passphrase, :blob #encrypted
        t.timestamps
      end

      add_index :company_managed_addresses, [:hashed_ethereum_address], unique: true, name: 'index_1'
    end

  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      drop_table :company_managed_addresses
    end
  end
end
