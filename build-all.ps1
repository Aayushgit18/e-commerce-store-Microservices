$services = @(
  "api-gateway",
  "auth-service",
  "user-service",
  "inventory-service",
  "order-service",
  "reviews-service",
  "notification-service",
  "eureka-service"
)

foreach ($service in $services) {
    Write-Host "🚀 Building $service..."
    Set-Location $service
    mvn clean install -DskipTests
    Set-Location ..
}

Write-Host "✅ All services built successfully!"