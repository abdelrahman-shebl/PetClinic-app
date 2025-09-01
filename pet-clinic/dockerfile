FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder

WORKDIR /app

COPY . .
 
RUN ./mvnw package

FROM  eclipse-temurin:17-jdk-alpine-3.22

WORKDIR /app

COPY  --from=builder /app/target/*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
