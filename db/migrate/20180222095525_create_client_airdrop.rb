class CreateClientAirdrop < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSaasAirdropDbConnection) do
      create_table :client_airdrops do |t|
        t.column :airdrop_uuid, :integer, null: false
        t.column :client_id, :integer, null: false
        t.column :client_branded_token_id, :integer, null: false
        t.column :airdrop_list_type, :tinyint, size: 1, null: false
        t.column :common_airdrop_amount_in_wei, :decimal, precision: 30, scale: 0, null: true
        t.column :common_expiry_timesatmp, :integer, null: false
        t.column :steps_complete, :tinyint, size: 1, default: 0, null: false
        t.column :status, :tinyint, size: 1, null: false
        t.column :data, :text, null: true
        t.timestamps
      end
      add_index :client_airdrops, :airdrop_uuid, unique: true, name: 'uniq_index_1'
    end
  end

  def down
    run_migration_for_db(EstablishSaasAirdropDbConnection) do
      drop_table :client_airdrops
    end
  end

end