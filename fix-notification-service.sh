#!/bin/bash

echo "Fixing missing notification-service..."

mkdir -p k8s/notification-service/templates

printf "%s\n" \
"apiVersion: v2
name: notification-service
version: 1.0.0" > k8s/notification-service/Chart.yaml

printf "%s\n" \
"image: notification-service:latest
port: 8080" > k8s/notification-service/values.yaml

printf "%s\n" \
"apiVersion: apps/v1
kind: Deployment
metadata:
  name: notification-service
  namespace: ecommerce
spec:
  selector:
    matchLabels:
      app: notification-service
  template:
    metadata:
      labels:
        app: notification-service
    spec:
      containers:
        - name: notification-service
          image: {{ .Values.image }}
          ports:
            - containerPort: {{ .Values.port }}" > k8s/notification-service/templates/deployment.yaml

printf "%s\n" \
"apiVersion: v1
kind: Service
metadata:
  name: notification-service
  namespace: ecommerce
spec:
  type: NodePort
  ports:
    - port: 8080
      nodePort: 30080
  selector:
    app: notification-service" > k8s/notification-service/templates/service.yaml

printf "%s\n" \
"apiVersion: v1
kind: ConfigMap
metadata:
  name: notification-service-config
  namespace: ecommerce
data:
  MODE: \"prod\"" > k8s/notification-service/templates/configmap.yaml

echo "🎉 notification-service created successfully!"
