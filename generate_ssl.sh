#!/bin/bash

# Создаем директорию для сертификатов
mkdir -p kafka_ssl
cd kafka_ssl

# 1. Генерируем CA (Certificate Authority)
openssl req -new -x509 -keyout ca-key -out ca-cert -days 365 -subj "/CN=Kafka-CA" -passout pass:123456
echo "01" > serial.txt
touch index.txt

# 2. Генерируем сертификаты для каждого брокера
for i in {1..4}
do
  # Генерируем ключ и запрос на подпись сертификата (CSR)
  openssl req -new -newkey rsa:2048 -nodes -keyout kafka${i}.key -out kafka${i}.csr -subj "/CN=kafka${i}"
  
  # Подписываем CSR с помощью CA
  openssl x509 -req -CA ca-cert -CAkey ca-key -in kafka${i}.csr -out kafka${i}.cert -days 365 -CAserial serial.txt -passin pass:123456
  
  # Создаем keystore для брокера
  openssl pkcs12 -export -in kafka${i}.cert -inkey kafka${i}.key -out kafka${i}.p12 -name kafka${i} -password pass:keystorepass
  keytool -importkeystore -destkeystore kafka.server.keystore.jks -srckeystore kafka${i}.p12 -srcstoretype pkcs12 -alias kafka${i} -deststorepass keystorepass -srcstorepass keystorepass
  
  # Импортируем CA cert в truststore
  keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass truststorepass -noprompt
  
  # Создаем файл с учетными данными
  echo "keystorepass" > keystore_creds
  echo "truststorepass" > truststore_creds
  echo "keypass" > key_creds
done

# 3. Генерируем клиентские сертификаты
openssl req -new -newkey rsa:2048 -nodes -keyout client.key -out client.csr -subj "/CN=kafka-client"
openssl x509 -req -CA ca-cert -CAkey ca-key -in client.csr -out client.cert -days 365 -CAserial serial.txt -passin pass:123456

# Создаем клиентский keystore
openssl pkcs12 -export -in client.cert -inkey client.key -out client.p12 -name kafka-client -password pass:keystorepass
keytool -importkeystore -destkeystore kafka.client.keystore.jks -srckeystore client.p12 -srcstoretype pkcs12 -alias kafka-client -deststorepass keystorepass -srcstorepass keystorepass

# Импортируем CA cert в клиентский truststore
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert -storepass truststorepass -noprompt

# Создаем файл client.properties для клиентов Kafka
cat > client.properties <<EOF
security.protocol=SSL
ssl.truststore.location=/etc/kafka/secrets/kafka.client.truststore.jks
ssl.truststore.password=truststorepass
ssl.keystore.location=/etc/kafka/secrets/kafka.client.keystore.jks
ssl.keystore.password=keystorepass
ssl.key.password=keypass
EOF

echo "SSL certificates generated successfully in kafka_ssl directory"