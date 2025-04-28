#!/bin/bash

# Копируем SSL сертификаты в Spark
docker cp kafka_ssl/kafka.client.keystore.jks spark-master:/opt/bitnami/spark/conf/
docker cp kafka_ssl/kafka.client.truststore.jks spark-master:/opt/bitnami/spark/conf/

# Запускаем Spark приложение
docker exec -it spark-master \
  /opt/bitnami/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.1 \
  /app/spark_analytics.py