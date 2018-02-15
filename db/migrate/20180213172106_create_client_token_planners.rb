class CreateClientTokenPlanners < DbMigrationConnection
  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      create_table :client_token_planners do |t|
        t.column :client_token_id, :integer, null: false
        t.column :token_worth_in_usd, :decimal, precision: 15, scale: 5, null: true
        t.column :initial_no_of_users, :integer, null: true
        t.column :initial_airdrop_in_wei, :decimal, precision: 30, scale: 0, null: true
        t.timestamps
      end

      add_index :client_token_planners, [:client_token_id], unique: true, name: 'index_1'

    end

  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      drop_table :client_tokens
    end
  end

end
