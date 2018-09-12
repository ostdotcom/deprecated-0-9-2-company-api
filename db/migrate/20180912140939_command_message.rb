class CommandMessage < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      create_table :command_message do |t|
        t.column :kind, :string, null: false
        t.column :topic_name, :string, null:true
        t.column :status, :integer, null: false
        t.column :extra_data, :string, null: true
        t.timestamps
        end
      end
  end

  def down
    run_migration_for_db(EstablishSaasConfigDbConnection) do
      drop_table :command_message
    end
  end
  end
