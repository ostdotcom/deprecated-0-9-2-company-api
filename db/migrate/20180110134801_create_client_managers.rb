class CreateClientManagers < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyClientDbConnection) do

      create_table :client_managers do |t|
        t.column :client_id, :integer, null: false
        t.column :user_id, :integer, null: false
        t.column :status, :tinyint, null: false
        t.timestamps
      end

      add_index :client_managers, [:client_id, :user_id], name: 'uk_1', unique: true

    end

  end

  def down

    run_migration_for_db(EstablishCompanyClientDbConnection) do
      drop_table :client_managers
    end

  end

end
