class CreateUserValidationHashes < DbMigrationConnection

  def change

    run_migration_for_db(EstablishCompanyUserDbConnection) do

      create_table :user_validation_hashes do |t|
        t.column :user_id, :integer, null: false
        t.column :validation_hash, :blob, null: false #encrypted
        t.column :kind, :tinyint, limit: 1, null: false
        t.column :usage_attempts, :tinyint, default: 0
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end

    end

  end

end
