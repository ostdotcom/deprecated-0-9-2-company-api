class AlterClientUsers < DbMigrationConnection

  def up
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      rename_column :client_users, :total_tokens_in_wei, :total_airdropped_tokens_in_wei
      add_column :client_users, :airdropped_token_balance_in_wei, :decimal, precision: 30, scale: 0, default: 0, after: :total_airdropped_tokens_in_wei
    end
  end

  def down
    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do
      rename_column :client_users, :total_airdropped_tokens_in_wei, :total_tokens_in_wei
      remove_column :client_users, :airdropped_token_balance_in_wei
    end
  end

end
