require 'redis'
require 'sinatra/base'
require 'sinatra'
# require 'sinatra/namespace'
# require "sinatra/reloader" if development?
require 'haml'
require 'json'

require './player'

class RedisPlayer < Sinatra::Base
#  register Sinatra::Namespace

  set :bind, '0.0.0.0'
  ### Share the public folder with NodeJS 
  set :public_folder, File.dirname(__FILE__) + '/../public'

  class << self
    attr_accessor :redis, :threads, :players
    attr_reader :connected
    def connect(options = {})
      
      host = options["host"] || "localhost" 
      port = options["port"]&.to_i || 6379
      auth = options["auth"] || nil

      if auth && !auth.empty? 
        @redis = Redis.new(host: host, port: port, password: auth) 
      else 
        @redis = Redis.new(host: host, port: port) 
      end
      @connected = true
      ## TODO: clean previous threads and players
      @threads = {}
      @players = {}
    end
  end

  self.connect()

  get '/' do
    haml :index, :layout => :layout
  end

  post '/connect' do 
    params.to_s
    RedisPlayer.connect(params)
    RedisPlayer.redis.connection[:id]
  end

  get '/history' do
    @first = RedisPlayer.redis.xrange("car-events", "-", "+", count: 1)
    haml :history, :layout => false
  end

  get '/reading_ratio' do 
    RedisPlayer.players["cars"]&.reading_ratio 
  end

  get '/play_tobii' do 
    player = Player.new
    player.parse_tobii_file('livedata.json')
    RedisPlayer.players["tobii"] = player
    RedisPlayer.threads["tobii"] = Thread.new { player.play(RedisPlayer.redis) }
  end
  
  get '/play_cars' do 
    player = Player.new
    player.parse_vehicle_file('car_live_data.json')

    RedisPlayer.players["cars2"] = player
    RedisPlayer.threads["cars2"] = Thread.new { player.play(RedisPlayer.redis) }
  end

  get '/play' do
    @events = RedisPlayer.redis.xrange("car-events", "-", "+")
    @first = @events
    ## Start playing at same speed, replay SET and PUBLISH of all the key/value logged
    player = Player.new
    player.parse_stream(@events)

    ## TODO: Use fibers instead of threads.
    RedisPlayer.players["cars"] = player
    RedisPlayer.threads["cars"]  = Thread.new { player.play(RedisPlayer.redis) }

    haml :history, :layout => false
  end

  known_json_keys = %w(cars zones)

  get '/get/:key' do 
    RedisPlayer.redis.get(params[:key])
  end

  get '/get-json/:key' do 
    JSON.parse(RedisPlayer.redis.get(params[:key])).to_s
  end

  get '/play/:key' do 
    k = params[:key]
    
    return "Already started" if RedisPlayer.players[k]
    @events = RedisPlayer.redis.xrange(k, "-", "+")
    @first = @events
    ## Start playing at same speed, replay SET and PUBLISH of all the key/value logged
    player = Player.new
    player.parse_stream(@events)

    ## TODO: Use fibers instead of threads.
    RedisPlayer.players[k] = player
    RedisPlayer.threads[k]  = Thread.new { player.play(RedisPlayer.redis) }
    "Started"
  end

  get '/stop/:key' do 
    k = params[:key]
    RedisPlayer.threads[k]&.kill

    RedisPlayer.threads[k] = nil
    RedisPlayer.players[k] = nil
    "Stopped"
  end

  get '/all-keys' do

    return "Not connected" if not RedisPlayer.connected
    @keys = RedisPlayer.redis.keys
    @types = @keys.map{ |key| RedisPlayer.redis.type(key)}
    haml :"keys", :layout => false
  end

  run! if app_file == $0
end