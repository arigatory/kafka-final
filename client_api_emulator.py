import json
import argparse
from kafka import KafkaProducer
from datetime import datetime

# Конфигурация
KAFKA_BROKERS = "localhost:9092"
QUERY_TOPIC = "client_queries"
STORAGE_FILE = "client_queries.log"


class ClientAPIEmulator:
    def __init__(self):
        self.producer = KafkaProducer(
            bootstrap_servers=KAFKA_BROKERS,
            value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        )

    def log_to_storage(self, data):
        """Логирование запросов в файл"""
        with open(STORAGE_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(data, ensure_ascii=False) + "\n")

    def send_to_kafka(self, query_type, data):
        """Отправка запроса в Kafka"""
        message = {
            "type": query_type,
            "data": data,
            "timestamp": datetime.utcnow().isoformat(),
        }

        self.producer.send(QUERY_TOPIC, value=message)
        self.log_to_storage(message)
        print(f"Запрос отправлен: {message}")

    def search_product(self, name):
        """Эмуляция поиска товара"""
        query_data = {"action": "search", "query": name, "user_id": "demo_user"}
        self.send_to_kafka("search", query_data)

    def get_recommendations(self, user_id):
        """Эмуляция получения рекомендаций"""
        query_data = {"action": "recommendations", "user_id": user_id}
        self.send_to_kafka("recommendations", query_data)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="CLIENT API Emulator")
    subparsers = parser.add_subparsers(dest="command")

    # Парсер для команды поиска
    search_parser = subparsers.add_parser("search")
    search_parser.add_argument("--name", required=True, help="Product name to search")

    # Парсер для команды рекомендаций
    rec_parser = subparsers.add_parser("recommend")
    rec_parser.add_argument(
        "--user-id", required=True, help="User ID for recommendations"
    )

    args = parser.parse_args()

    api = ClientAPIEmulator()

    if args.command == "search":
        api.search_product(args.name)
    elif args.command == "recommend":
        api.get_recommendations(args.user_id)
    else:
        parser.print_help()
