class AddColumnProcessIdInClientWorkerManagedAddressIds < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      add_column :client_worker_managed_address_ids, :process_id, :integer, null:true, after: :id
      add_index :client_worker_managed_address_ids, [:process_id], name: 'i_2'
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      remove_index :client_worker_managed_address_ids, name: 'i_2'
      remove_column :client_worker_managed_address_ids, :process_id
    end
  end

end
