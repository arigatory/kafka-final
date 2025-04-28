import json
import time
from kafka import KafkaProducer
from kafka.errors import KafkaError

# Конфигурация Kafka
KAFKA_BROKERS = "localhost:9092"
TOPIC_NAME = "products"


class ShopAPIEmulator:
    def __init__(self):
        self.producer = KafkaProducer(
            bootstrap_servers=KAFKA_BROKERS,
            value_serializer=lambda v: json.dumps(v).encode("utf-8"),
            security_protocol="SSL",  # Для TLS
            ssl_cafile="ca.pem",
            ssl_certfile="service.cert",
            ssl_keyfile="service.key",
        )

    def load_products_from_file(self, file_path):
        """Загрузка товаров из JSON файла"""
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"Ошибка загрузки файла: {e}")
            return []

    def send_to_kafka(self, products):
        """Отправка товаров в Kafka"""
        for product in products:
            try:
                # Добавляем timestamp перед отправкой
                product["kafka_timestamp"] = int(time.time() * 1000)

                future = self.producer.send(
                    TOPIC_NAME, value=product, key=product["product_id"].encode("utf-8")
                )

                # Блокируем отправку для демонстрации
                future.get(timeout=10)
                print(f"Отправлен товар: {product['name']}")

            except KafkaError as e:
                print(f"Ошибка отправки в Kafka: {e}")

    def run(self, file_path):
        """Основной цикл работы эмулятора"""
        products = self.load_products_from_file(file_path)
        if products:
            self.send_to_kafka(products)
        else:
            print("Нет товаров для отправки")


if __name__ == "__main__":
    emulator = ShopAPIEmulator()
    emulator.run("products.json")
