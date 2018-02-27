class CreatePreGeneratedEncryptionSalts < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasBigDbConnection) do

      create_table :pre_generated_encryption_salts do |t|
        t.column :encryption_salt, :blob, null: false #kms_encrypted
        t.timestamps
      end

    end
  end

  def down
    run_migration_for_db(EstablishSaasBigDbConnection) do
      drop_table :pre_generated_encryption_salts
    end
  end
end
