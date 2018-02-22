class AddColumnInClientBrandedTokens < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      add_column :client_branded_tokens, :airdrop_contract_addr, :string, after: :token_erc20_address

    end

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      add_column :client_tokens, :airdrop_contract_addr, :string, after: :token_erc20_address

    end

  end

  def down

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      remove_column :client_branded_tokens, :airdrop_contract_addr

    end

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      remove_column :client_tokens, :airdrop_contract_addr

    end

  end
end
