class CreateUserValidationHashes < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyUserDbConnection) do

      create_table :user_validation_hashes do |t|
        t.column :user_id, :integer, null: false
        t.column :validation_hash, :text, null: false #encrypted
        t.column :kind, :tinyint, limit: 1, null: false
        t.column :usage_attempts, :tinyint, default: 0
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end

    end

  end

  def down

    run_migration_for_db(EstablishCompanyUserDbConnection) do
      drop_table :user_validation_hashes
    end

  end

end
