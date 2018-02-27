class FetchOraclePricePoints

  def self.perform
    CacheManagement::OSTPricePoints.new([1]).fetch[1]
  end

end