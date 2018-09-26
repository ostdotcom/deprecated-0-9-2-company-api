class CreateProcessQueueAssociation < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      create_table :process_queue_association do |t|
        t.column :process_id, :integer, null: false
        t.column :rmq_config_id, :integer, null: false
        t.column :queue_name_suffix, :string, null:false
        t.column :status, :integer, null: false
        t.timestamps
      end

      add_index :process_queue_association, [:process_id, :queue_name_suffix], name: 'process_queue_index', unique: true
    end
  end

  def down
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      remove_index :process_queue_association, name:'process_queue_index'
      drop_table :process_queue_association
    end
  end

end


