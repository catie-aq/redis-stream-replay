class VehicleEvent

  attr_reader :time_stamp, :data
  def initialize(data)
    @time_stamp = data[:timestamp] * 1000.0  ## Convert to ms
    p "Timestamp #{@time_stamp}"
    @data = data
    @key = "raw-cars"
  end

  def send(redis)
    redis.set(@key, @data.to_json)
    redis.publish(@key, @data.to_json)
    # redis.xadd("car-events2", [[key, @value.to_json]].to_h)
  end
end
