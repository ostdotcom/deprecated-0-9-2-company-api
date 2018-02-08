class FetchClientOstBalance

  include Util::ResultHelper

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def initialize(params)

    @client_id = params[:client_id]

  end

  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def perform

    ost_balance = Memcache.get_set_memcached(memcache_key, memcache_expiry) do
      0.008 #TODO: fix this
    end

    success_with_data(
      ost_balance: ost_balance,
      ost_usd_conversion_factor: FetchOstUsdConversionFactor.perform
    )

  end

  private

  def memcache_key_obj
    @m_k_obj ||= MemcacheKey.new('client.ost_balance')
  end

  def memcache_key
    memcache_key_obj.key_template % {id: @client_id}
  end

  def memcache_expiry
    memcache_key_obj.expiry
  end

end