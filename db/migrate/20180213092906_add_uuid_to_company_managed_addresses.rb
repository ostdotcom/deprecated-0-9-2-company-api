class AddUuidToCompanyManagedAddresses < DbMigrationConnection
  def up
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      add_column :company_managed_addresses, :uuid, :string, null: true, after: :id

      add_index :company_managed_addresses, :uuid, name: 'index_on_uuid'

    end
  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      remove_column :company_managed_addresses, :uuid

    end
  end
end
