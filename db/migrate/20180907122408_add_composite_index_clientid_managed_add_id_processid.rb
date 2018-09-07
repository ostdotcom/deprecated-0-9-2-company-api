class AddCompositeIndexClientidManagedAddIdProcessid < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      add_index :client_worker_managed_address_ids, [:client_id, :process_id], name: 'i_3', unique:true
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      remove_index :client_worker_managed_address_ids, name: 'i_3'
    end
  end
end



