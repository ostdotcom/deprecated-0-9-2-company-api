class CreateClientUsers < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      create_table :client_users do |t|
        t.column :client_id, :integer, null: false
        t.column :name, :string, null: false
        t.column :company_managed_address_id, :integer, null: false
        t.column :total_tokens_in_wei, :decimal, precision: 30, scale: 0, default: 0
        t.column :status, :tinyint, null: false
        t.timestamps
      end

      add_index :client_users, [:client_id, :company_managed_address_id], unique: true, name: 'index_1'
    end

  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      drop_table :client_users
    end
  end

end
