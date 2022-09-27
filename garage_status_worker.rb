require 'redis'
require 'date'
require 'net/http'
require 'sidekiq'

WEBHOOK_SECRET = ENV['IFTTT_SECRET']
REDIS_PROVIDER = if ENV['REDIS_PROVIDER']
  if ENV['REDIS_PROVIDER'].match(/[\w_]+/)
    ENV[ENV['REDIS_PROVIDER']]
  else
    ENV['REDIS_PROVIDER']
  end
end

class GarageStatusWorker
  include Sidekiq::Worker

  @@redis = if REDIS_PROVIDER
      Redis.new(url: REDIS_PROVIDER)
    else
      Redis.new(host: "localhost", port: 6379, db: 11)
    end

  def perform(interval)
    last_closed = @@redis.lindex('garage_status:door_closed', 0)
    @@redis.ltrim('garage_status:door_closed', 0, 999)
    last_opened = @@redis.lindex('garage_status:door_opened', 0)
    @@redis.ltrim('garage_status:door_opened', 0, 999)
    return puts "No Last Opened" unless last_opened

    last_opened = DateTime.parse(last_opened).to_time

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