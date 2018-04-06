class CreateClientWorkerManagedAddressIds < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      create_table :client_worker_managed_address_ids do |t|
        t.column :client_id, :integer, null: false
        t.column :managed_address_id, :integer, null: false
        t.column :properties, :tinyint, null: false, limit: 1, default: 0
        t.column :status, :tinyint, null: false, limit: 1
        t.timestamps
      end
      add_index :client_worker_managed_address_ids, [:client_id, :managed_address_id], name: 'i_1', unique: true
    end
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      remove_column :client_tokens, :worker_addr_uuid
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      drop_table :client_worker_managed_address_ids
    end
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      add_column :client_tokens, :worker_addr_uuid, :string, after: :reserve_uuid
    end
  end

end
