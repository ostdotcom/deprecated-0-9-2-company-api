class ClientAddress < EstablishCompanyClientEconomyDbConnection

  enum status: {
      GlobalConstant::ClientAddress.active_status => 1,
      GlobalConstant::ClientAddress.inactive_status => 2
  }

  # Hash an eth address by SHA algo
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  # @param [String] eth_address (mandatory) - eth address
  #
  # @return [String]
  #
  def self.get_hashed_eth_address(eth_address)
    LocalCipher.new("").get_hashed_text(eth_address.downcase)
  end

end
