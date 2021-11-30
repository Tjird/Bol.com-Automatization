#!/bin/bash

BOLAUTH=$(redis-cli -n 8 get bolauth)

if [[ -z "$BOLAUTH" ]]
then
  url="https://login.bol.com/token?grant_type=client_credentials"
  header="Authorization: Basic $(redis-cli -n 8 get base64)"
  result=$(curl -X POST -H "$header" -H "Accept: application/json" -H "Content-Type: application/json" -s $url | jq -r '.access_token')
  if [[ -z "$result" ]]
  then
    echo "Mistake by getting access token from bol.com"
    exit 0
  else
    BOLAUTH="$result"
    redis-cli -n 8 setex bolauth 298 "$result"
  fi
fi

url="https://api.bol.com/retailer-demo/orders?fulfilment-method=FBR"
header="Authorization: Bearer $BOLAUTH"
result=$(curl -X GET -H "$header" -H "Accept: application/vnd.retailer.v4+json" -H "Content-Type: application/vnd.retailer.v4+json" -s $url | jq -r '.orders')

if [[ $result == "null" ]] || [[ -z "$result" ]]
then
  echo "Mistake by getting open orders from bol.com"
  exit 0
elif [[ $result != *"orderId"* ]]
then
  exit 0
fi

curl -X POST -H "Content-Type: application/json" -d "$result" -s "http://localhost:8801/api/insertOrders"
