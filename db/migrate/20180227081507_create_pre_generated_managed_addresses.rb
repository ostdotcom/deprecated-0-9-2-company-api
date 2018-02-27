class CreatePreGeneratedManagedAddresses < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasBigDbConnection) do

      create_table :pre_generated_managed_addresses do |t|
        t.column :ethereum_address, :string, null: false
        t.column :passphrase, :text, null: false
        t.column :pre_generated_encryption_salt_id, :integer, null: false, limit: 5
        t.column :lock, :integer, null: true
        t.column :status, :tinyint, null: false, limit: 1, default: 0
        t.timestamps
      end

      add_index :pre_generated_managed_addresses, :status, name: 'index_1'
    end
  end

  def down
    run_migration_for_db(EstablishSaasBigDbConnection) do
      drop_table :pre_generated_managed_addresses
    end
  end
end
