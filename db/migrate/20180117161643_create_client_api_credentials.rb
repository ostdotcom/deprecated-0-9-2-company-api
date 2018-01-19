class CreateClientApiCredentials < DbMigrationConnection
  def change

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      create_table :client_api_credentials do |t|
        t.column :client_id, :integer, null: false
        t.column :api_key, :string, null: false
        t.column :api_secret, :blob, null: false #encrypted
        t.timestamps
      end

      add_index :client_api_credentials, [:client_id], name: 'index_1'
      add_index :client_api_credentials, [:api_key], name: 'index_2'

    end

  end
end
