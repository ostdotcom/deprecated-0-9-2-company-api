class CreateManagedAddressSalts < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      create_table :managed_address_salts do |t|
        t.column :client_id, :integer, null: false
        t.column :managed_address_salt, :blob, null: false #kms_encrypted
        t.timestamps
      end

      add_index :managed_address_salts, :client_id, name: 'uniq_client_id', uniq: true
    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      drop_table :managed_address_salts

    end
  end
end
