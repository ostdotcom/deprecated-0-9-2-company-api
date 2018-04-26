class CreateWhiteListedDomain < DbMigrationConnection

  def up
    run_migration_for_db(EstablishCompanyUserDbConnection) do
      create_table :whitelisted_domains do |t|
        t.string :domain, null: false
        t.timestamps
      end
    end
  end

  def down
    run_migration_for_db(EstablishCompanyUserDbConnection) do
      drop_table :whitelisted_domains
    end
  end

end
