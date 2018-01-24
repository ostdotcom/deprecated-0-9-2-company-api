class AddColumnsToClientTokens < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      add_column :client_tokens, :initial_number_of_users, :integer, null: true, after: :conversion_rate
      add_column :client_tokens, :airdrop_bt_per_user, :decimal, null: true, after: :conversion_rate

    end

  end

  def down

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      remove_column :client_tokens, :initial_number_of_users
      remove_column :client_tokens, :airdrop_bt_per_user

    end

  end

end
