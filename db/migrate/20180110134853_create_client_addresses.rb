class CreateClientAddresses < DbMigrationConnection

  def change

    run_migration_for_db(EstablishCompanyClientEconomyDbConnection) do

      create_table :client_addresses do |t|
        t.column :ethereum_address, :blob, null: false #encrypted
        t.column :hashed_ethereum_address, :blob, null: false #encrypted
        t.column :client_id, :integer, null: false
        t.column :status, :tinyint, null: false
        t.timestamps
      end

    end

  end

end
