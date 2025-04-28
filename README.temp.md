# kafka-final

Установите зависимости: pip install -r requirements.txt

Запустите SHOP API: python shop_api_emulator.py

Используйте CLIENT API:

Поиск: python client_api_emulator.py search --name "Умные часы"

Рекомендации: python client_api_emulator.py recommend --user-id user123

Создайте SSL сертификаты и поместите их в папку kafka_ssl

Запустите кластер: docker-compose up -d

Настройте топики и ACL: docker exec -it kafka-tools /scripts/setup_kafka.sh

Этот конфиг обеспечивает:

3 ноды основного кластера Kafka с TLS

1 ноду резервного кластера

Репликацию с фактором 3 и min.insync.replicas=2

ACL для защиты топиков

MirrorMaker для дублирования данных

JMX для мониторинга

Пример сообщения в топике recommendations:
{
  "category": "Электроника",
  "product_count": 42,
  "avg_price": 24500.50,
  "total_available": 1250,
  "timestamp": "2023-11-15T14:30:00.000Z"
}


Для запуска системы:

docker-compose up -d

./setup_kafka.sh

./run_analytics.sh


4. Пример данных в Elasticsearch
Для товаров (index: filtered_products):

json
{
  "product_id": "12345",
  "name": "Умные часы XYZ",
  "description": "Умные часы с функцией мониторинга здоровья...",
  "price": {
    "amount": 4999.99,
    "currency": "RUB"
  },
  "category": "Электроника",
  "brand": "XYZ",
  "stock": {
    "available": 150,
    "reserved": 20
  },
  "@timestamp": "2023-11-15T12:00:00Z"
}
Для запросов клиентов (index: client_queries):
{
  "type": "search",
  "data": {
    "action": "search",
    "query": "часы",
    "user_id": "user123"
  },
  "timestamp": "2023-11-15T12:05:22Z",
  "@timestamp": "2023-11-15T12:05:22Z"
}

5. Kibana Dashboard
После накопления данных можно создать визуализации в Kibana (http://localhost:5601):

Создайте index patterns для filtered_products и client_queries

Создайте дашборды с:

Топ категорий товаров

Статистика поисковых запросов

Графики активности пользователей

Как развернуть систему:
Добавьте сервисы в docker-compose.yml

Запустите: docker-compose up -d

Настройте коннекторы: ./setup_elasticsearch_connector.sh

Проверьте данные в Elasticsearch или Kibana

Эта реализация обеспечивает:

Надежное хранение данных в Elasticsearch

Полнотекстовый поиск по товарам

Аналитику пользовательских запросов

Масштабируемую архитектуру

Интеграцию с Kafka через Connect

Визуализацию данных через Kibana

5. Запуск и проверка
Запустите систему: docker-compose up -d

Проверьте метрики в Prometheus: http://localhost:9090

Откройте Grafana: http://localhost:3000 (логин: admin, пароль: admin)

Импортируйте дашборд или создайте свой

Проверьте Alertmanager: http://localhost:9093

Для тестирования алертов можно остановить один из брокеров:

docker stop kafka1

Рекомендуемые метрики Kafka для мониторинга:

kafka_network_RequestMetrics_RequestsPerSec: Запросы в секунду

kafka_server_BrokerTopicStats_MessagesInPerSec: Сообщения в секунду

kafka_log_Log_Size: Размер логов

kafka_server_ReplicaManager_LeaderCount: Количество лидеров

kafka_server_SessionExpireListener_ZooKeeperAuthFailures: Ошибки аутентификации Zookeeper