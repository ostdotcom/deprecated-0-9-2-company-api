class CreateClients < DbMigrationConnection
  def change

    run_migration_for_db(EstablishCompanyClientDbConnection) do

      create_table :clients do |t|
        t.column :properties, :tinyint, null: true
        t.column :info_salt, :string, null: false
        t.column :status, :tinyint, null: false
        t.timestamps
      end

    end
  end
end
