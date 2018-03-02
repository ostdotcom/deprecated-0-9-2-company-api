class CreateEventLog < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasBigDbConnection) do

      create_table :event_logs do |t|
        t.column :kind, :string, null: false
        t.column :event_data, :text, null: false
        t.timestamps
      end

      add_index :event_logs, :kind, name: 'index_1'
    end
  end

  def down
    run_migration_for_db(EstablishSaasBigDbConnection) do
      drop_table :event_logs
    end
  end
end
