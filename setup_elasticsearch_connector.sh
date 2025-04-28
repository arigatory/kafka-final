#!/bin/bash

# Ожидаем доступности Kafka Connect
while [ $(curl -s -o /dev/null -w %{http_code} http://kafka-connect:8083/connectors) -ne 200 ]
do
  echo "Waiting for Kafka Connect to be ready..."
  sleep 5
done

# Создаем коннектор для товаров
curl -X POST http://kafka-connect:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "elasticsearch-sink-products",
    "config": {
      "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
      "tasks.max": "1",
      "topics": "filtered_products",
      "key.ignore": "true",
      "connection.url": "http://elasticsearch:9200",
      "type.name": "_doc",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable": "false",
      "schema.ignore": "true",
      "key.converter": "org.apache.kafka.connect.storage.StringConverter",
      "transforms": "extractTimestamp",
      "transforms.extractTimestamp.type": "org.apache.kafka.connect.transforms.InsertField$Value",
      "transforms.extractTimestamp.timestamp.field": "@timestamp",
      "behavior.on.malformed.documents": "ignore",
      "behavior.on.null.values": "ignore"
    }
  }'

# Создаем коннектор для запросов клиентов
curl -X POST http://kafka-connect:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "elasticsearch-sink-queries",
    "config": {
      "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
      "tasks.max": "1",
      "topics": "client_queries",
      "key.ignore": "true",
      "connection.url": "http://elasticsearch:9200",
      "type.name": "_doc",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable": "false",
      "schema.ignore": "true",
      "key.converter": "org.apache.kafka.connect.storage.StringConverter",
      "transforms": "extractTimestamp",
      "transforms.extractTimestamp.type": "org.apache.kafka.connect.transforms.InsertField$Value",
      "transforms.extractTimestamp.timestamp.field": "@timestamp"
    }
  }'

echo "Elasticsearch connectors configured successfully"