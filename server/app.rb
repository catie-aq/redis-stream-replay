require 'redis'
require 'sinatra/base'
require 'sinatra'
# require 'sinatra/namespace'
require "sinatra/reloader" if development?
require 'haml'
require 'json'

require './player'

class RedisPlayer < Sinatra::Base
#  register Sinatra::Namespace

  set :public_folder, File.dirname(__FILE__) + '/../public'

  $redis = Redis.new

  get '/' do
    haml :index, :layout => :layout
  end

  get '/history' do 
    @first = $redis.xrange("car-events", "-", "+", count: 1)  
    haml :history, :layout => false
  end

  get '/play' do 
    @events = $redis.xrange("car-events", "-", "+")
    @first = @events
    ## Start playing at same speed, replay SET and PUBLISH of all the key/value logged
    player = Player.new 
    player.parse(@events)
    p "Playing"

    Thread.new { player.play($redis) }
    
    haml :history, :layout => false
  end

  get '/all-keys' do 
    @keys = $redis.keys
    haml :"keys", :layout => false
  end

  # run! if app_file == $0
end