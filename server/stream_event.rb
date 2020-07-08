class StreamEvent
  attr_reader :time_stamp, :status, :data
  def initialize(data)
    @time_stamp = data[:ts] / 1000.0  ## Convert to ms
    @status = data[:s].to_i
    @data = data
    @type = find_type
    find_gaze_type if @type == EventType::GAZE
    find_device_event_type if is_device_type?
  end

  def send(redis)
    if @type == EventType::GAZE
      if @eye
        key = "gaze:#{@eye}:#{@gaze_type}"
      else
        key = "gaze:#{@gaze_type}"
      end
    end

    if is_device_type?
      key = "device:#{@input_type}"
    end

    redis.set(key, @value.to_json)
    redis.publish(key, @value.to_json)
    redis.xadd("eye_tracker", [[key, @value.to_json]].to_h)
  end

  private

  def find_type
    return EventType::GAZE          if @data.has_key? :gidx
    return EventType::ACCELEROMETER if @data.has_key? :ac
    return EventType::GYROSCOPE     if @data.has_key? :gy
    return EventType::PTS_SYNC      if @data.has_key? :pts
    return EventType::OTHER
  end

  def is_device_type?
    @type == EventType::ACCELEROMETER or @type == EventType::GYROSCOPE
  end

  ## Gaze Direction, Pupil center & pupil diameter
  def eye_props; %i[gd pc pd] ; end
  ## Gaze position & position 3D
  def look_props; %i[gp gp3] ; end
  ## Accelerometer & gyroscope
  def device_props; %i[ac gy] ; end

  def find_device_event_type
    device_props.each do |name|
      if @data.has_key? name
        @input_type = name
        @value = @data[name]
      end
    end
  end

  def find_gaze_type
    @gidx = data[:gidx].to_i

    eye_props.each do |name|
      if @data.has_key? name
        @gaze_type = name
        @eye = data[:eye].to_sym
        @value = @data[name]
        return
      end
    end

    look_props.each do |name|
      if @data.has_key? name
        @gaze_type = name
        @value = @data[name]
        return
      end
    end
  end

end
