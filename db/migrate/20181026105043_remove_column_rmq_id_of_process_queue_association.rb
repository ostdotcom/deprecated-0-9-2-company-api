class RemoveColumnRmqIdOfProcessQueueAssociation < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      remove_column :process_queue_association, :rmq_config_id
    end
  end
  
  def down
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      add_column :process_queue_association, :rmq_config_id, :integer, after: :process_id, null: false
    end
  end
end