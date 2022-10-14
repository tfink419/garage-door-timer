require 'json'
require 'net/http'
require 'date'
require 'aws-sdk-dynamodb'

IFTTT_SECRET = ENV['IFTTT_SECRET']

def get_garage_door_statuses(dynamodb_client)
  output_string = ""
  result = dynamodb_client.scan(table_name: "GarageDoorStatuses")
  result.items
rescue StandardError => e
  e
end

def lambda_handler(event:, context:)
  region = 'us-west-2'

  dynamodb_client = Aws::DynamoDB::Client.new(region: region)

  statuses = get_garage_door_statuses(dynamodb_client)
  
  grouped = statuses.group_by { |s| s['door_name'] }

  grouped.transform_values do |door_statuses|
    opened_at = door_statuses.find { |s| s['event'] == 'door_opened' }.dig('created_at')
    closed_at = door_statuses.find { |s| s['event'] == 'door_closed' }.dig('created_at')
    opened_at = opened_at.empty? ? nil : DateTime.parse(opened_at).to_time 
    closed_at = closed_at.empty? ? nil : DateTime.parse(closed_at).to_time

    if !opened_at.nil? &&
          (closed_at.nil? || opened_at > closed_at) &&
          opened_at <= Time.now - 300
        Net::HTTP.get('maker.ifttt.com', "/trigger/garage_door_timed_out/json/with/key/#{IFTTT_SECRET}")
    else
      if opened_at.nil? || (!closed_at.nil? && opened_at < closed_at)
        reason = 'door_not_closed'
      else
        reason = 'door_opened_five_minutes_or_less'
      end
      "Close command not sent: #{reason}"
    end
  end
end

