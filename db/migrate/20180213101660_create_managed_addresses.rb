class CreateManagedAddresses < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      create_table :managed_addresses do |t|
        t.column :client_id, :integer, null: true
        t.column :managed_address_salt_id, :integer, null: true
        t.column :address_type, :tinyint, null: false, limit: 1
        t.column :uuid, :string, null: false
        t.column :name, :string
        t.column :ethereum_address, :string, limit: 255
        t.column :private_key, :text
        t.column :status, :tinyint, null: false, limit: 1
        t.column :properties, :tinyint, limit: 1, default: 0
        t.timestamps
      end

      add_index :managed_addresses, [:client_id, :uuid], name: 'uk_1', unique: true
      add_index :managed_addresses, [:managed_address_salt_id], name: 'uk_2', unique: true
      add_index :managed_addresses, [:ethereum_address], name: 'uk_3', unique: true

      execute ("ALTER TABLE managed_addresses AUTO_INCREMENT = 70000")

    end

  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      drop_table :managed_addresses

    end
  end
end
