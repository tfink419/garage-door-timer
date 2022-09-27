require 'json'
require 'date'
require 'redis'

WEBHOOK_SECRET = ENV['IFTTT_SECRET']
REDIS_PROVIDER = if ENV['REDIS_PROVIDER']
  if ENV['REDIS_PROVIDER'].match(/[\w_]+/)
    ENV[ENV['REDIS_PROVIDER']]
  else
    ENV['REDIS_PROVIDER']
  end
end
class RackApp
  @@redis = if REDIS_PROVIDER
    Redis.new(url: REDIS_PROVIDER)
  else
    Redis.new(host: "localhost", port: 6379, db: 11)
  end

  def call(env)
    req = Rack::Request.new(env)
    begin
      body = JSON.parse(req.body.read)
    rescue
      return [
        400,
        {"content-Type" => "plain/text"},
        ["Bad Request"]
      ]
    end

    unless body['webhook_secret'] == WEBHOOK_SECRET
      return [
        401,
        {"content-Type" => "plain/text"},
        ["Unauthorized"]
      ]
    end

    event = body['event']

    created_at = nil
    begin
      created_at = DateTime.parse(body['created_at'])
    rescue
      created_at = DateTime.now
    end

    case event
    when 'door_opened'
      @@redis.lpush('garage_status:door_opened', created_at.iso8601)
    when 'door_closed'
      @@redis.lpush('garage_status:door_closed', created_at.iso8601)
    end

    [
      200,
      {"content-Type" => "plain/text"},
      ["Success"]
    ]
  end
end

app = RackApp.new
run app