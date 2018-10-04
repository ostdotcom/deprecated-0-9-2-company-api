class AddChainIdInProcessQueueAssociation < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      add_column :process_queue_association, :chain_id, :integer, after: :id, :null => false
    end
  end

  def down
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      remove_column :process_queue_association, :chain_id
    end
  end
end
