# coding: utf-8
require "json"
require "redis"

# Add active support extensions for time manipulations
require 'active_support/all'


#### DEPRECATED FILE, HERE TO COPY INTO SERVER CODE 

# redis = Redis.new(host: "10.0.1.1", port: 6380, db: 15)
redis = Redis.new

require "./event_type"
require "./stream_event"

## Max length 2.10mn
beginning_of_time = nil
beginning_of_gidx = nil
stream_time = []
gidx_time = []

## Time resolution: millisecond.
File.readlines('livedata.json').each do |line|
  json = JSON.parse line
  json = json.transform_keys(&:to_sym)
  # p json.to_s
  event = StreamEvent.new(json)
  beginning_of_time = event.time_stamp if beginning_of_time.nil?

  elapsed = (event.time_stamp - beginning_of_time).round
  stream_time[elapsed] ||= []
  stream_time[elapsed] << event
  # p elapsed
end

stream_s = stream_time.size / 1000.0 # / 60.0
p "Stream time is #{stream_s} seconds"

## Try : while loop -> read all, then loop if event > current elapsed time.
## IDEA array of what to do at each TS.

last_read = 0
start_time = Time.now
end_time = start_time + stream_s.seconds
small_amount_of_time = 0.001 # 0.0001

while(Time.now < end_time)

  ## substraction gives time in seconds, convert to ms and round it to integer.
  stream_idx = ((Time.now - start_time) * 1000.0).round

  ## Do not do twice
  if stream_idx == last_read
#    p "Sleep a little here"
    sleep small_amount_of_time
    next
  end

  #  stream_time[last_read..stream_idx].each
  ((last_read+1)..stream_idx).each do |time_index|
    next if stream_time[time_index].nil?

#    p "Time index #{time_index}"
    stream_time[time_index].each do |stream_event|
      stream_event.send(redis)
    end
  end

  last_read = stream_idx
  sleep small_amount_of_time
  # p "Tick #{stream_idx}"
end

[1, 2, ... 10, 12, 15, 20]
