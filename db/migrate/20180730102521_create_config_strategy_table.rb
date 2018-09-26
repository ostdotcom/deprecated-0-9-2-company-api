class CreateConfigStrategyTable < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSaasConfigDbConnection) do

      create_table :config_strategies do |t|
        t.column :kind, :tinyint, limit: 1, null: false
        t.column :params, :text, null: false #encrypted
        t.column :hashed_params, :text, null: false
        t.column :managed_address_salts_id, :integer,limit: 8, null:false
        t.timestamps
      end

    end

  end

  def down

    run_migration_for_db(EstablishSaasConfigDbConnection) do

      drop_table :config_strategies

    end

  end

end
