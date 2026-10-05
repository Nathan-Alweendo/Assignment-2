# Phase 1: Build the artifact using the Ballerina Swan Lake environment
FROM ballerina/ballerina:2201.13.5 AS builder
USER root
WORKDIR /home/ballerina/src
COPY . .
RUN bal build --cloud="none"

# Phase 2: FIXED: Use Java 21 (eclipse-temurin:21-jre-jammy) to match compilation formats perfectly
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=builder /home/ballerina/src/target/bin/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
