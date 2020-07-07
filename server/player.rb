# coding: utf-8
require "json"
require "redis"
# Add active support extensions for time manipulations
require 'active_support/all'


class Event  
    attr_reader :time_stamp, :data
    def initialize(event_data)
        @time_stamp = event_data[0].split("-")[0].to_i
        @key = event_data[1].keys.first
        @value = event_data[1].values.first
    end

    def send(redis)
        p "Sending to #{@key} "
        redis.set(@key, @value)
        redis.publish(@key, @value)
    end
end

class Player 
    attr_accessor :small_amount_of_time;

    def initialize()
        @beginning_of_time = nil
        @stream_time = []
        @small_amount_of_time = 0.001 # 0.0001
    end

    def parse(stream)
        # We know it is exactly ordered
        @beginning_of_time = Event.new(stream.first).time_stamp

        stream.each do |stream_event|
            event = Event.new(stream_event)
            @beginning_of_time = event.time_stamp if @beginning_of_time.nil?
            elapsed = (event.time_stamp - @beginning_of_time).round

            p "elapsed #{elapsed} "
            @stream_time[elapsed] ||= []
            @stream_time[elapsed] << event
        end
    end

    def play(redis)
        
        stream_s = @stream_time.size / 1000.0 # / 60.0
        p "Stream time is #{stream_s} seconds"

        last_read = 0
        start_time = Time.now
        end_time = start_time + stream_s.seconds 

        while(Time.now < end_time)


            ## substraction gives time in seconds, convert to ms and round it to integer.
            stream_idx = ((Time.now - start_time) * 1000.0).round
            p "Playing..  #{stream_idx}"
            ## Do not play twice
            if stream_idx == last_read
            #    p "Sleep a little here"
                sleep small_amount_of_time
                next
            end

            #  stream_time[last_read..stream_idx].each
            ((last_read+1)..stream_idx).each do |time_index|
                next if @stream_time[time_index].nil?

                ## Send the redis commands
                @stream_time[time_index].each do |stream_event|
                    stream_event.send(redis)
                end
            end 
            
            ## Note the last read and sleep a little to relieve the CPU
            last_read = stream_idx
            sleep small_amount_of_time
            
        end
    end
end


    # def parseJSON()
    #     File.readlines('car_live_data.json').each do |line|
    #     json = JSON.parse line
    #     json = json.transform_keys(&:to_sym)
    #     # p json.to_s

    #     event = VehicleEvent.new(json)
    #     @beginning_of_time = event.time_stamp if @beginning_of_time.nil?

    #     @elapsed = (event.time_stamp - @beginning_of_time).round

    #     # p elapsed
    #     @stream_time[elapsed] ||= []
    #     @stream_time[elapsed] << event
    # # p elapsed
    # end

## Max length 2.10mn
# beginning_of_time = nil
# beginning_of_gidx = nil
# stream_time = []
# gidx_time = []


