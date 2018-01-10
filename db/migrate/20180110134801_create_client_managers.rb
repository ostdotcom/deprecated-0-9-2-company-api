class CreateClientManagers < DbMigrationConnection
  def change

    run_migration_for_db(EstablishCompanyClientDbConnection) do

      create_table :client_managers do |t|
        t.column :client_id, :integer, null: false
        t.column :user_id, :integer, null: false
        t.column :status, :tinyint, null: false
        t.timestamps
      end

    end
  end
end
