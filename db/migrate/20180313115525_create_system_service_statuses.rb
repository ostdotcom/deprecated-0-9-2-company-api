class CreateSystemServiceStatuses < DbMigrationConnection

  def up
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      create_table :system_service_statuses do |t|
        t.column :name, :tinyint, null: false
        t.column :status, :tinyint, null: false
        t.integer :down_since, null: true
        t.integer :resumed_on, null: true
        t.timestamps
      end
    end
  end

  def down
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do
      drop_table :system_service_statuses
    end
  end

end
