#!/bin/bash

echo "📁 Creating folder structure..."

mkdir -p k8s
mkdir -p k8s/infra/kafka/templates
mkdir -p k8s/infra/postgres/templates
mkdir -p k8s/infra/eureka/templates

SERVICES=(
  "api-gateway"
  "auth-service"
  "user-service"
  "inventory-service"
  "order-service"
  "reviews-service"
  "notification-service"
)

for svc in "${SERVICES[@]}"; do
  mkdir -p k8s/$svc/templates
done

echo "✍️ Writing namespace..."
printf "%s\n" \
"apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce" > k8s/namespace.yaml


#############################################
# INFRA — KAFKA + ZOOKEEPER
#############################################

printf "%s\n" \
"apiVersion: v2
name: kafka
description: Kafka + Zookeeper for ecommerce microservices
type: application
version: 1.0.0
appVersion: \"7.4\"" > k8s/infra/kafka/Chart.yaml

printf "%s\n" \
"zookeeper:
  image: confluentinc/cp-zookeeper:7.4.0
  port: 2181

kafka:
  image: confluentinc/cp-kafka:7.4.0
  port: 9092
  zookeeperConnect: zookeeper:2181" > k8s/infra/kafka/values.yaml

printf "%s\n" \
"apiVersion: apps/v1
kind: Deployment
metadata:
  name: zookeeper
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zookeeper
  template:
    metadata:
      labels:
        app: zookeeper
    spec:
      containers:
      - name: zookeeper
        image: {{ .Values.zookeeper.image }}
        ports:
        - containerPort: {{ .Values.zookeeper.port }}" > k8s/infra/kafka/templates/zookeeper-deployment.yaml

printf "%s\n" \
"apiVersion: v1
kind: Service
metadata:
  name: zookeeper
  namespace: ecommerce
spec:
  selector:
    app: zookeeper
  ports:
  - port: 2181
    targetPort: 2181" > k8s/infra/kafka/templates/zookeeper-service.yaml

printf "%s\n" \
"apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: {{ .Values.kafka.image }}
        env:
        - name: KAFKA_ZOOKEEPER_CONNECT
          value: \"{{ .Values.kafka.zookeeperConnect }}\"
        - name: KAFKA_ADVERTISED_LISTENERS
          value: \"PLAINTEXT://kafka:{{ .Values.kafka.port }}\"
        ports:
        - containerPort: {{ .Values.kafka.port }}" > k8s/infra/kafka/templates/kafka-deployment.yaml

printf "%s\n" \
"apiVersion: v1
kind: Service
metadata:
  name: kafka
  namespace: ecommerce
spec:
  selector:
    app: kafka
  ports:
  - port: 9092
    targetPort: 9092" > k8s/infra/kafka/templates/kafka-service.yaml

#############################################
# INFRA — POSTGRES
#############################################

printf "%s\n" \
"apiVersion: v2
name: postgres
description: Postgres DB
type: application
version: 1.0.0" > k8s/infra/postgres/Chart.yaml

printf "%s\n" \
"postgres:
  image: postgres:16
  db: ecommerce
  user: postgres
  password: postgres
  port: 5432" > k8s/infra/postgres/values.yaml

printf "%s\n" \
"apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: ecommerce
data:
  POSTGRES_DB: \"{{ .Values.postgres.db }}\"
  POSTGRES_USER: \"{{ .Values.postgres.user }}\"
  POSTGRES_PASSWORD: \"{{ .Values.postgres.password }}\"" > k8s/infra/postgres/templates/postgres-configmap.yaml

printf "%s\n" \
"apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: {{ .Values.postgres.image }}
        envFrom:
        - configMapRef:
            name: postgres-config
        ports:
        - containerPort: 5432" > k8s/infra/postgres/templates/postgres-deployment.yaml

printf "%s\n" \
"apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: ecommerce
spec:
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: postgres" > k8s/infra/postgres/templates/postgres-service.yaml

#############################################
# INFRA — EUREKA
#############################################

printf "%s\n" \
"apiVersion: v2
name: eureka
description: Eureka discovery server
type: application
version: 1.0.0" > k8s/infra/eureka/Chart.yaml

printf "%s\n" \
"image: eureka-service:latest
port: 8761" > k8s/infra/eureka/values.yaml

printf "%s\n" \
"apiVersion: apps/v1
kind: Deployment
metadata:
  name: eureka
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: eureka
  template:
    metadata:
      labels:
        app: eureka
    spec:
      containers:
      - name: eureka
        image: {{ .Values.image }}
        ports:
        - containerPort: {{ .Values.port }}" > k8s/infra/eureka/templates/deployment.yaml

printf "%s\n" \
"apiVersion: v1
kind: Service
metadata:
  name: eureka
  namespace: ecommerce
spec:
  selector:
    app: eureka
  ports:
  - port: 8761
    targetPort: 8761" > k8s/infra/eureka/templates/service.yaml

#############################################
# ALL MICROservices TEMPLATES
#############################################

echo "✍️ Writing microservice Helm charts..."

for svc in "${SERVICES[@]}"; do

printf "%s\n" \
"apiVersion: v2
name: $svc
description: Helm chart for $svc
type: application
version: 1.0.0" > k8s/$svc/Chart.yaml

printf "%s\n" \
"image: $svc:latest
port: 8080" > k8s/$svc/values.yaml

printf "%s\n" \
"apiVersion: apps/v1
kind: Deployment
metadata:
  name: $svc
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $svc
  template:
    metadata:
      labels:
        app: $svc
    spec:
      containers:
      - name: $svc
        image: {{ .Values.image }}
        ports:
        - containerPort: {{ .Values.port }}" > k8s/$svc/templates/deployment.yaml

printf "%s\n" \
"apiVersion: v1
kind: Service
metadata:
  name: $svc
  namespace: ecommerce
spec:
  selector:
    app: $svc
  ports:
  - port: {{ .Values.port }}
    targetPort: {{ .Values.port }}" > k8s/$svc/templates/service.yaml

printf "%s\n" \
"apiVersion: v1
kind: ConfigMap
metadata:
  name: $svc-config
  namespace: ecommerce
data:
  ENV: \"docker\"" > k8s/$svc/templates/configmap.yaml

done

echo "🎉 ALL K8s + Helm YAML FILES CREATED SUCCESSFULLY!"
