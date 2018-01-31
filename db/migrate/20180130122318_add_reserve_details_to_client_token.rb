class AddReserveDetailsToClientToken < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      add_column :client_tokens, :reserve_address, :string, null: true, after: :erc20_address
      add_column :client_tokens, :reserve_passphrase, :string, null: true, after: :reserve_address

    end

  end

  def down

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      remove_column :client_tokens, :reserve_address
      remove_column :client_tokens, :reserve_passphrase

    end

  end

end
