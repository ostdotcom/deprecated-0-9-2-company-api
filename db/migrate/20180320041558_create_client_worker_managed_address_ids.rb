class CreateClientWorkerManagedAddressIds < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      create_table :client_worker_managed_address_ids do |t|
        t.column :client_id, :integer, null: false
        t.column :managed_address_id, :integer, null: false
        t.column :status, :tinyint, null: false, limit: 1
      end
      remove_column :client_tokens, :worker_addr_uuid
      add_index :client_worker_managed_address_ids, [:client_id], name: 'i_1', unique: false
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      drop_table :client_worker_managed_address_ids
    end
  end

end
