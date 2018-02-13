class CreateSassClientTokens < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      create_table :client_tokens do |t|
        t.column :client_id, :integer, null: false
        t.column :reserve_managed_address_id, :string
        t.column :token_erc20_address, :string
        t.column :token_uuid, :string
        t.column :conversion_rate, :decimal, null: true, precision: 12, scale: 6
        t.column :managed_address_salt, :blob, null: false #kms_encrypted
        t.timestamps
      end

    end
  end

  def down
    run_migration_for_db(EstablishSaasClientEconomyDbConnection) do

      drop_table :client_tokens

    end
  end
end
