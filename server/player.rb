# coding: utf-8
require "json"
require "redis"
# Add active support extensions for time manipulations
require 'active_support/all'

require './stream_event'
require './vehicle_event'

class Event  
    attr_reader :time_stamp, :data

    def initialize(event_data)
        @time_stamp = event_data[0].split("-")[0].to_i
        @data = event_data[1]      
    end

    def send(redis)
        @data.each_pair do |key, value| 
            # p "Sending to #{key} " 
            redis.set(key, value)
            redis.publish(key, value)     
        end
    end
end

class Player 
    attr_accessor :small_amount_of_time
    attr_reader :stream_idx, :stream_time

    def initialize()
        @beginning_of_time = nil
        @stream_time = []
        @small_amount_of_time = 0.001 # 0.0001
    end

    ## TODO: Factorize all of this to a single method
    def parse_tobii_file(file)
        File.readlines(file).each do |line|
            json = JSON.parse line
            json = json.transform_keys(&:to_sym)
            event = TobiiStreamEvent.new(json)
            @beginning_of_time = event.time_stamp if @beginning_of_time.nil?
        
            elapsed = (event.time_stamp - beginning_of_time).round
            @steam_time[elapsed] ||= []
            @steam_time[elapsed] << event
        end
    end

    def parse_vehicle_file(file)
        ## Time resolution: millisecond.
        File.readlines(file).each do |line|
            json = JSON.parse line
            json = json.transform_keys(&:to_sym)
            # p json.to_s
        
            event = VehicleEvent.new(json)
            beginning_of_time = event.time_stamp if beginning_of_time.nil?       
            elapsed = (event.time_stamp - beginning_of_time).round
        
            # p elapsed
            @stream_time[elapsed] ||= []
            @stream_time[elapsed] << event
            # p elapsed
        end
    end

    def parse_stream(stream)
        # We know it is exactly ordered
        # @beginning_of_time = Event.new(stream.first).time_stamp
        stream.each do |stream_event|
            event = Event.new(stream_event)
            @beginning_of_time = event.time_stamp if @beginning_of_time.nil?
            elapsed = (event.time_stamp - @beginning_of_time).round

            # p "elapsed #{elapsed} "
            @stream_time[elapsed] ||= []
            @stream_time[elapsed] << event
        end
    end

    def reading_ratio
        return 0 unless @stream_time && @stream_idx
        return @stream_time.size / @stream_idx
    end

    def play(redis)   
        @stream_idx = 0 
        stream_s = @stream_time.size / 1000.0 # / 60.0
        p "Stream time is #{stream_s} seconds"

        last_read = 0
        start_time = Time.now
        end_time = start_time + stream_s.seconds 

       
        while(Time.now < end_time)

            # return if @stream_idx >= 200

            ## substraction gives time in seconds, convert to ms and round it to integer.
            @stream_idx = ((Time.now - start_time) * 1000.0).round
            p "Playing..  #{@stream_idx}"
            ## Do not play twice
            if @stream_idx == last_read
                p "Sleep a little here, same index"
                sleep small_amount_of_time
                # next
            end

            redis.pipelined do 
                #  stream_time[last_read..@stream_idx].each
                ((last_read+1)..@stream_idx).each do |time_index|
                    next if @stream_time[time_index].nil?

                    ## Send the redis commands
                    @stream_time[time_index].each do |stream_event|
                        stream_event.send(redis)
                    end
                end 
            end
            
            ## Note the last read and sleep a little to relieve the CPU
            last_read = @stream_idx
            
            p "Sleeping... all sent"
            sleep small_amount_of_time
            
        end

        # p "END OF STREAM ! #{end_time}"
    end
end