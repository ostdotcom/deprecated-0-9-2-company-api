class CreateClientAirdropDetails < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasAirdropDbConnection) do
      create_table :client_airdrop_details do |t|
        t.column :client_id, :integer, null: false
        t.column :client_airdrop_id, :integer, null: false
        t.column :managed_address_id, :integer, null: false
        t.column :airdrop_amount_in_wei, :decimal, precision: 30, scale: 0, null: false
        t.column :expiry_timesatmp, :integer, null: false
        t.column :status, :tinyint, size: 1, null: false
        t.timestamps
      end
      add_index :client_airdrop_details, [:client_airdrop_id, :managed_address_id], unique: true, name: 'uniq_index_1'
      add_index :client_airdrop_details, [:client_id, :managed_address_id], unique: false, name: 'index_2'

    end
  end

  def down
    run_migration_for_db(EstablishSaasAirdropDbConnection) do
      drop_table :client_airdrop_details
    end
  end

end