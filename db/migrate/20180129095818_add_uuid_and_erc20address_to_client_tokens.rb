class AddUuidAndErc20addressToClientTokens < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      add_column :client_tokens, :uuid, :string, null: true, after: :symbol
      add_column :client_tokens, :erc20_address, :string, null: true, after: :uuid

    end

  end

  def down

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      remove_column :client_tokens, :uuid
      remove_column :client_tokens, :erc20_address

    end

  end

end
