class CreateClientTokens < DbMigrationConnection

  def change

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      create_table :client_tokens do |t|
        t.column :client_id, :integer, null: false
        t.column :company_managed_addresses_id, :integer, null: true
        t.column :name, :string, null: false
        t.column :symbol, :string, null: false
        t.column :symbol_icon, :string, null: true
        t.column :conversion_rate, :decimal, precision: 30, scale: 10, null: true
        t.column :setup_steps, :tinyint, null: true
        t.column :status, :tinyint, null: false
        t.timestamps
      end

    end

  end

end
