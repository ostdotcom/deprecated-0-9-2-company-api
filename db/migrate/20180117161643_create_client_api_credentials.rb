class CreateClientApiCredentials < DbMigrationConnection
  def up

    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do

      create_table :client_api_credentials do |t|
        t.column :client_id, :integer, null: false
        t.column :api_key, :string, null: false
        t.column :api_secret, :text, null: false #encrypted
        t.column :api_salt, :blob, null: false #kms_encrypted
        t.column :expiry_timestamp, :integer, null: false
        t.timestamps
      end

      add_index :client_api_credentials, [:api_key], name: 'uniq_api_key', uniq: true
      add_index :client_api_credentials, [:client_id, :expiry_timestamp], name: 'index_client_id_expiry_timestamp'

    end

  end

  def down
    run_migration_for_db(EstablishCompanySaasSharedDbConnection) do

      drop_table :client_api_credentials

    end
  end

end
