# Use the official Ballerina runtime environment image
FROM ballerina/ballerina:2201.13.5 AS builder
USER root
WORKDIR /home/ballerina/src
COPY . .
# Compile the production artifact directly inside the container environment
RUN bal build --cloud="none"

FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
# Extract the compiled binary package from the builder phase layer cleanly
COPY --from=builder /home/ballerina/src/target/bin/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
