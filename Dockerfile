FROM bde2020/spark-base:3.1.1-hadoop3.2

COPY spark_analytics.py /app/
COPY kafka_ssl /opt/bitnami/spark/conf/kafka_ssl

RUN chmod +x /app/spark_analytics.py