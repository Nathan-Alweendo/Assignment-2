# DSA612S Assignment 2 — Food Delivery Platform

This repository holds the microservices for our distributed food delivery platform using Ballerina, Apache Kafka, and MongoDB.

## Getting Started for Developers

### Prerequisites
1. Install [Docker Desktop](https://docker.com)
2. Install [Ballerina](https://ballerina.io)

### Step 1: Clone and Run Shared Infrastructure
Run this command from the root directory (`assignment-2`) to spin up Kafka and the shared Database:
```bash
docker compose up -d
```

### Step 2: Build Your Service
1. Navigate into your respective service directory (e.g., `cd order-service`).
2. Run your microservice against the local infrastructure framework.
3. Consult `TOPICS.md` for proper naming schemas and data constraints.
