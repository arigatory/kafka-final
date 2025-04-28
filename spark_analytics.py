from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
import json

def main():
    # Создаем Spark сессию
    spark = SparkSession.builder \
        .appName("MarketplaceAnalytics") \
        .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.1") \
        .getOrCreate()

    # Схема для данных о товарах
    product_schema = StructType([
        StructField("product_id", StringType()),
        StructField("name", StringType()),
        StructField("description", StringType()),
        StructField("price", StructType([
            StructField("amount", DoubleType()),
            StructField("currency", StringType())
        ])),
        StructField("category", StringType()),
        StructField("brand", StringType()),
        StructField("stock", StructType([
            StructField("available", IntegerType()),
            StructField("reserved", IntegerType())
        ])),
        StructField("sku", StringType()),
        StructField("tags", ArrayType(StringType())),
        StructField("specifications", MapType(StringType(), StringType())),
        StructField("created_at", StringType()),
        StructField("updated_at", StringType()),
        StructField("store_id", StringType())
    ])

    # Читаем данные из Kafka
    df = spark.readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", "kafka-backup1:9099") \
        .option("subscribe", "products") \
        .option("startingOffsets", "earliest") \
        .option("kafka.security.protocol", "SSL") \
        .option("kafka.ssl.truststore.location", "/opt/bitnami/spark/conf/kafka.client.truststore.jks") \
        .option("kafka.ssl.truststore.password", "truststorepass") \
        .option("kafka.ssl.keystore.location", "/opt/bitnami/spark/conf/kafka.client.keystore.jks") \
        .option("kafka.ssl.keystore.password", "keystorepass") \
        .option("kafka.ssl.key.password", "keypass") \
        .load()

    # Парсим JSON
    parsed_df = df.select(
        from_json(col("value").cast("string"), product_schema).alias("data") \
        .select("data.*")

    # Аналитика: агрегации по категориям
    analytics_df = parsed_df.groupBy("category") \
        .agg(
            count("*").alias("product_count"),
            avg("price.amount").alias("avg_price"),
            sum("stock.available").alias("total_available")
        ) \
        .withColumn("timestamp", current_timestamp())

    # Записываем результаты в HDFS
    hdfs_query = parsed_df.writeStream \
        .format("parquet") \
        .option("path", "hdfs://hadoop-namenode:9000/data/products") \
        .option("checkpointLocation", "hdfs://hadoop-namenode:9000/checkpoints/products") \
        .start()

    # Записываем аналитику в Kafka
    kafka_query = analytics_df.select(
        to_json(struct("*")).alias("value")
    ).writeStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", "kafka1:9093") \
        .option("topic", "recommendations") \
        .option("kafka.security.protocol", "SSL") \
        .option("kafka.ssl.truststore.location", "/opt/bitnami/spark/conf/kafka.client.truststore.jks") \
        .option("kafka.ssl.truststore.password", "truststorepass") \
        .option("kafka.ssl.keystore.location", "/opt/bitnami/spark/conf/kafka.client.keystore.jks") \
        .option("kafka.ssl.keystore.password", "keystorepass") \
        .option("kafka.ssl.key.password", "keypass") \
        .option("checkpointLocation", "hdfs://hadoop-namenode:9000/checkpoints/recommendations") \
        .start()

    # Ожидаем завершения
    hdfs_query.awaitTermination()
    kafka_query.awaitTermination()

if __name__ == "__main__":
    main()