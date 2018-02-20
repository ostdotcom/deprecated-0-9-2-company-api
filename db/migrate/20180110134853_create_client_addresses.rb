class CreateClientAddresses < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      create_table :client_addresses do |t|
        t.column :client_id, :integer, null: false
        t.column :ethereum_address, :text, null: false #encrypted
        t.column :hashed_ethereum_address, :string, null: false #encrypted
        t.column :address_salt, :blob, null: false #encrypted
        t.column :status, :tinyint, null: false
        t.timestamps
      end

      add_index :client_addresses, [:hashed_ethereum_address], unique: true, name: 'index_1'
      add_index :client_addresses, [:client_id, :status], name: 'index_2'

      execute ("ALTER TABLE client_addresses AUTO_INCREMENT = 50000")

    end
  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      drop_table :client_addresses
    end
  end

end
