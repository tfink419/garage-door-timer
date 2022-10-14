require 'json'
require 'aws-sdk-dynamodb'

IFTTT_SECRET = ENV['IFTTT_SECRET']

def table_item_updated?(dynamodb_client, table_item)
  dynamodb_client.update_item(table_item)
end

def lambda_handler(event:, context:)
  body = nil
  begin
    body = JSON.parse(event['body'])
  rescue
    return { statusCode: 400, body: JSON.generate("Bad Request") }
  end
  return { statusCode: 403, body: JSON.generate("Forbidden") } unless body['webhook_secret'] == IFTTT_SECRET

  region = 'us-west-2'
  table_name = 'GarageDoorStatuses'
  door_name = body["door_name"]
  event_name = body["event"]

  dynamodb_client = Aws::DynamoDB::Client.new(region: region)

  table_item = {
    table_name: table_name,
  }

  table_item = {
    table_name: table_name,
    key: {
      door_name: door_name,
      event: event_name
    },
    update_expression: 'SET created_at = :time',
    expression_attribute_values: { ":time": Time.now.iso8601 },
    return_values: 'UPDATED_NEW'
  }

  results = table_item_updated?(dynamodb_client, table_item)
  { 
    statusCode: 200,
    body: JSON.generate(results)
  }
  rescue StandardError => err
    { 
      statusCode: 500,
      body: JSON.generate(err)
    }
end

