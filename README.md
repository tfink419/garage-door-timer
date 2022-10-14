# IFTTT Door Timer Closer

## Description
This is a basic app that uses webhooks to communicate with IFTTT and close a door if it has been open longer than a specified time

## How to Use
This is designed to be used on AWS Lambda and integrate with DynamoDB, create two lamdba functions, the one labeled `garage_door_status_updater` needs a webhook, and both need to be connected to a DynamoDB.
