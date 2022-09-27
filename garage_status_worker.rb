require 'redis'
require 'date'
require 'net/http'
require 'sidekiq'
require 'pry'

WEBHOOK_SECRET = ENV['IFTTT_SECRET']

class GarageStatusWorker
  include Sidekiq::Worker

  @@redis = if ENV['REDIS_URL']
      Redis.new(url: ENV['REDIS_URL'])
    else
      Redis.new(host: "localhost", port: 6379, db: 11)
    end

  def perform(interval)
    last_closed = @@redis.lindex('garage_status:door_closed', 0)
    last_opened = @@redis.lindex('garage_status:door_opened', 0)
    return puts "No Last Opened" unless last_opened

    last_opened = DateTime.parse(last_opened).to_time

    binding.pry

    if (last_closed && DateTime.parse(last_closed).to_time > last_opened)
      return puts "Last Closed since Last Opened"
    end
    
    if last_opened >= Time.now - interval
      return puts "Last Opened less than interval of #{interval} seconds"
    end

    puts "Door was left opened longer than #{interval} seconds, sending webhook"
    Net::HTTP.get('maker.ifttt.com', "/trigger/garage_door_timed_out/json/with/key/#{WEBHOOK_SECRET}")
  end
end