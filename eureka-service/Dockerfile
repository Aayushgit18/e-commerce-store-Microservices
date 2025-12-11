FROM --platform=linux/amd64 maven:3.8.5-openjdk-17 AS build
COPY . /usr/app
WORKDIR /usr/app
RUN mvn clean package -DskipTests

FROM --platform=linux/amd64 openjdk:17
VOLUME /tmp
COPY --from=build /usr/app/target/*.jar eureka-service.jar
ENTRYPOINT ["java","-jar","/eureka-service.jar"]
EXPOSE 8761

