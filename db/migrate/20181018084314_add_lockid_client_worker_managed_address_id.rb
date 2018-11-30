class AddLockidClientWorkerManagedAddressId < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      add_column :client_worker_managed_address_ids, :lock_id, :decimal, null: true, precision: 20, scale: 5, after: :status
      add_index :client_worker_managed_address_ids, [:lock_id], name: 'i_4'
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      remove_index :client_worker_managed_address_ids, name: 'i_4'
      remove_column :client_worker_managed_address_ids, :lock_id
    end
  end

end
