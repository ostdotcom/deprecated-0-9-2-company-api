class AddColumnInManageAddressesAndClientBrandedTokens < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      add_column :managed_addresses, :address_type, :tinyint, null: false, limit: 1, default: 1, after: :name

      add_column :client_branded_tokens, :worker_managed_address_id, :integer, after: :reserve_managed_address_id
      add_column :client_branded_tokens, :airdrop_holder_managed_address_id, :integer, after: :worker_managed_address_id
      add_column :client_branded_tokens, :simple_stake_contract_addr, :string, after: :token_erc20_address

    end

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      add_column :client_tokens, :worker_addr_uuid, :string, after: :reserve_uuid
      add_column :client_tokens, :airdrop_holder_addr_uuid, :string, after: :worker_addr_uuid
      add_column :client_tokens, :simple_stake_contract_addr, :string, after: :token_erc20_address

    end

  end

  def down

    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      remove_column :managed_addresses, :address_type

      remove_column :client_branded_tokens, :worker_managed_address_id
      remove_column :client_branded_tokens, :airdrop_holder_managed_address_id
      remove_column :client_branded_tokens, :simple_stake_contract_addr

    end

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      remove_column :client_tokens, :worker_addr_uuid
      remove_column :client_tokens, :airdrop_holder_addr_uuid
      remove_column :client_tokens, :simple_stake_contract_addr

    end

  end
end
