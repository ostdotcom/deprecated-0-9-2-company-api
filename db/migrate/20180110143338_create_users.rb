class CreateUsers < DbMigrationConnection

  def change

    run_migration_for_db(EstablishCompanyUserDbConnection) do

      create_table :users do |t|
        t.column :email, :string, null: false
        t.column :password, :blob, null: false #encrypted
        t.column :login_salt, :blob, null: true #encrypted
        t.column :properties, :tinyint, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end

    end

  end

end
