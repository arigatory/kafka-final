#!/bin/bash

# Ожидаем доступности Kafka
echo "Waiting for Kafka to be ready..."
cub kafka-ready -b kafka1:9093 1 20 --config /etc/kafka/secrets/client.properties
cub kafka-ready -b kafka2:9095 1 20 --config /etc/kafka/secrets/client.properties
cub kafka-ready -b kafka3:9097 1 20 --config /etc/kafka/secrets/client.properties

# Создаем топики
echo "Creating topics..."
kafka-topics --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --create --topic products --partitions 3 --replication-factor 3 --config min.insync.replicas=2

kafka-topics --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --create --topic client_queries --partitions 3 --replication-factor 3 --config min.insync.replicas=2

kafka-topics --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --create --topic recommendations --partitions 3 --replication-factor 3 --config min.insync.replicas=2

kafka-topics --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --create --topic filtered_products --partitions 3 --replication-factor 3 --config min.insync.replicas=2

# Настраиваем ACL
echo "Setting up ACLs..."
kafka-acls --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --add --allow-principal User:shop-api --operation Write --topic products

kafka-acls --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --add --allow-principal User:client-api --operation Write --topic client_queries

kafka-acls --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --add --allow-principal User:analytics --operation Read --topic products --group analytics-group

kafka-acls --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --add --allow-principal User:analytics --operation Write --topic recommendations

kafka-acls --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --add --allow-principal User:stream-processor --operation Read --topic products --group stream-group

kafka-acls --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
  --add --allow-principal User:stream-processor --operation Write --topic filtered_products

# Настраиваем MirrorMaker для дублирования данных во второй кластер
echo "Setting up MirrorMaker..."
kafka-mirror-maker --consumer.config /etc/kafka/secrets/mm-consumer.properties \
                   --producer.config /etc/kafka/secrets/mm-producer.properties \
                   --whitelist "products,client_queries,recommendations,filtered_products" \
                   --num.streams 2 &



# Добавьте в setup_kafka.sh ACL для аналитической системы:
# kafka-acls --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
#   --add --allow-principal User:spark --operation Read --topic products --group spark-group

# kafka-acls --bootstrap-server kafka1:9093 --command-config /etc/kafka/secrets/client.properties \
#   --add --allow-principal User:spark --operation Write --topic recommendations