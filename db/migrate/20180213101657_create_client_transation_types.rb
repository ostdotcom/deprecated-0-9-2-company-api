class CreateClientTransationTypes < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      create_table :client_transation_types do |t|
        t.column :client_id, :integer, null: false
        t.column :name, :string, null: false
        t.column :kind, :tinyint, null: false, limit: 1 # 1: user_to_user, 2: user_to_company, 3: company_to_user
        t.column :currency_type, :tinyint, null: false, limit: 1 # 1: usd, 2: bt
        t.column :value_in_usd, :decimal, null: true, precision: 10, scale: 5
        t.column :value_in_bt_wei, :decimal, null: true, precision: 30, scale: 0
        t.column :commission_percent, :decimal, null: false, precision: 6, scale: 3
        t.column :status, :tinyint, null: false, limit: 1
        t.timestamps
      end

      add_index :client_transation_types, [:client_id, :name], name: 'uniq_client_id_name', uniq:true

    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      drop_table :client_transation_types

    end
  end
end
