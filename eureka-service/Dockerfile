FROM maven:3.8.5-openjdk-17 AS build
WORKDIR /usr/app
COPY . .
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre
VOLUME /tmp
COPY --from=build /usr/app/target/*.jar eureka-service.jar
EXPOSE 8761
ENTRYPOINT ["java","-jar","/eureka-service.jar"]
