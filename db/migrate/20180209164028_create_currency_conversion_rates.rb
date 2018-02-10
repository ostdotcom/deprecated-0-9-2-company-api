class CreateCurrencyConversionRates < DbMigrationConnection

  def up

    run_migration_for_db(EstablishCompanyBigDbConnection) do

      create_table :currency_conversion_rates do |t|
        t.column :base_currency, :tinyint, limit: 1, null: false
        t.column :quote_currency, :tinyint, limit: 1, null: false
        t.column :conversion_rate, :decimal, precision: 12, scale: 6, null: false
        t.column :timestamp, :integer, null: false
        t.column :transaction_hash, :string, null: true
        t.column :status, :tinyint, null: false
        t.timestamps
      end

    end

  end

  def down

    run_migration_for_db(EstablishCompanyBigDbConnection) do
      drop_table :currency_conversion_rates
    end

  end

end
