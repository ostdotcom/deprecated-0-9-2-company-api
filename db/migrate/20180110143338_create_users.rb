class CreateUsers < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyUserDbConnection) do

      create_table :users do |t|
        t.column :email, :string, null: false
        t.column :password, :text, null: false #encrypted
        t.column :login_salt, :blob, null: true #encrypted
        t.column :properties, :tinyint, null: false
        t.column :default_client_id, :integer, null: true
        t.column :failed_login_attempt_count, :integer, null: true
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end

      add_index :users, :email, name: 'uk_1', unique: true

    end

  end

  def down

    run_migration_for_db(EstablishCompanyUserDbConnection) do

      drop_table :users

    end

  end

end
