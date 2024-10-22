class ClientTokenPlanner < EstablishCompanyClientEconomyDbConnection

  # Format data to a format which goes into cache
  # NOTE: All numeric values are in String as they go out to FE
  #
  # * Author: Puneet
  # * Date: 01/02/2018
  # * Reviewed By:
  #
  # @return [Hash]
  #
  def formated_cache_data
    {
      id: id,
      client_token_id: client_token_id,
      token_worth_in_usd: token_worth_in_usd.to_s,
      initial_no_of_users: initial_no_of_users,
      initial_airdrop_in_wei: initial_airdrop_in_wei.to_s,
      initial_airdrop: initial_airdrop_in_wei.blank? ? initial_airdrop_in_wei : Util::Converter.from_wei_value(initial_airdrop_in_wei).to_s
    }
  end

  def self.max_allowed_token_worth_in_usd
    GlobalConstant::Base.main_sub_environment? ? 1 : 10
  end

end
