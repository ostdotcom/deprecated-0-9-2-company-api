class CreateManagedAddresses < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      create_table :managed_addresses do |t|
        t.column :client_id, :integer, null: false
        t.column :uuid, :string, null: false
        t.column :name, :string
        t.column :ethereum_address, :text
        t.column :hashed_ethereum_address, :string
        t.column :passphrase, :text
        t.column :status, :tinyint, null: false, limit: 1
        t.timestamps
      end

      add_index :managed_addresses, [:client_id, :uuid], name: 'uniq_client_id_uuid'
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      drop_table :managed_addresses

    end
  end
end
