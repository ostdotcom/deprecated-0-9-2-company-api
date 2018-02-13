class CreateClients < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyClientDbConnection) do

      create_table :clients do |t|
        t.column :client_name, :string, null: true
        t.column :client_website, :string, null: true
        t.column :status, :tinyint, null: false
        t.timestamps
      end

    end

  end

  def down

    run_migration_for_db(EstablishCompanyClientDbConnection) do
      drop_table :clients
    end

  end

end
