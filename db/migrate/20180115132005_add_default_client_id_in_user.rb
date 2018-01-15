class AddDefaultClientIdInUser < DbMigrationConnection

  def self.up
    run_migration_for_db(EstablishCompanyUserDbConnection) do
      add_column :users, :default_client_id, :integer, after: :properties
    end
  end

  def self.down
    run_migration_for_db(EstablishCompanyUserDbConnection) do
      remove_column :users, :default_client_id
    end
  end

end
