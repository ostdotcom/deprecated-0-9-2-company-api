class AddNextActionAtInCwma < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      add_column :client_worker_managed_address_ids, :next_action_at, :integer, null: false, default: 0, after: :lock_id
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do
      remove_column :client_worker_managed_address_ids, :next_action_at
    end
  end

end
