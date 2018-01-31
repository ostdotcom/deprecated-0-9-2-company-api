class CompanyManagedAddress < EstablishCompanyClientEconomyDbConnection

  # Given an Ethereum address find out company managed address record
  #
  # Author:: Pankaj
  # Date:: 31/01/2018
  #
  def self.get_company_address_record(eth_address)
    hashed_addr = LocalCipher.get_sha_hashed_text(eth_address)
    where(hashed_ethereum_address: hashed_addr).first
  end

end
