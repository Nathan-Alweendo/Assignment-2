# 🍔 Distributed Event-Driven Food Delivery Platform
### **Course Code: DSA612S — Assignment 2**
### **System Architecture Control Panel & Microservices Cluster**

This repository contains a decentralized, event-driven food delivery infrastructure built using **Ballerina**, orchestrated via **Docker Compose**, and backed by an isolated **Database-per-Service** strategy using **MongoDB** and **Apache Kafka**.

---

## 👥 Team Responsibility Matrix & Contributions

| Microservice | Developer | GitHub Account | Core Architectural Responsibility |
| :--- | :--- | :--- | :--- |
| **order-service**<br>*(Central Orchestrator)* | **Nathan**<br>*(Team Lead)* | [Nathan-Alweendo](https://github.com) | Exposes the primary synchronous client checkout REST API (`POST /orders`), manages core state transformations, generates order tracking UUIDs, and drives the central lifecycle machine. |
| **admin-service**<br>*(Data Warehouse)* | **Nathan**<br>*(Team Lead)* | [Nathan-Alweendo](https://github.com) | Asynchronously consumes core transactional logs (`orders.created`, `payments.failed`, `restaurant.rejected`) to dynamically compute business metrics, revenues, and cancellation ratios. |
| **payment-service** | **Terry** | [nkululekodipura-cmyk](https://github.com) | Evaluates customer billing transaction logic loops upon intercepting order arrivals. Emits validation events indicating payment status results. |
| **delivery-service** | **Terry** | [nkululekodipura-cmyk](https://github.com) | Coordinates driver dispatch systems. Captures restaurant kitchen approvals to assign active couriers and emits continuous fulfillment tracking coordinates. |
| **restaurant-service** | **Kennedy** | [Kennydidit16](https://github.com) | Manages menu records, pricing, and live stock tallies. Intercepts incoming orders to perform isolated multi-pass inventory allocation checks before emitting ticket responses. |
| **customer-service** | **Doctrine** | [doctrine206](https://github.com) | Handles profile registry configuration blocks, address verification data, and hooks into delivery dispatch streams to provide account visibility updates. |
| **notification-service**| **Eugene** | [EugeneSondo](https://github.com) | Functions as a pure event consumer (no persistent storage). Intercepts platform alert streams to generate terminal output simulations modeling text/email notifications. |

---

## 🛠️ Data Isolation & Storage Strategy

To avoid tight database coupling and single-point-of-failure (SPOF) vulnerabilities, the platform enforces a strict **Database-per-Service architecture**:
*   `order_db` ──▶ Managed exclusively by `order-service`
*   `admin_db` ──▶ Managed exclusively by `admin-service`
*   `restaurant_db` ──▶ Managed exclusively by `restaurant-service`
*   `customer_db` ──▶ Managed exclusively by `customer-service`
*   `payment_db` ──▶ Managed exclusively by `payment-service`
*   `delivery_db` ──▶ Managed exclusively by `delivery-service`
*   *Notification Service runs entirely stateless.*

---

## 🚀 System Deployment & Startup Guide

Follow this exact sequence to spin up the entire cluster and launch the graphical web frontend for evaluation.

### Prerequisite Checklist
*   Ensure **Docker Desktop** is open, running, and completely green.
*   Ensure your terminal environment is running **Java 21** compatibility settings.

### 1. Boot the Entire Backend Infrastructure (1 Command)
Open a PowerShell terminal window inside the root directory (`assignment-2/`) and execute:
```powershell
docker compose up --build -d
```
*This handles multi-stage container builds, downloads required Kafka/Zookeeper/MongoDB layers, binds cross-origin (CORS) rules on IP `0.0.0.0`, and launches all 7 microservices concurrently inside the virtual cluster network.*

### 2. Verify System Cluster Health
Ensure all parts of the application cluster are active:
```powershell
docker ps
```
*Verify that a clean array displaying **all 9 containers** pops up green in your terminal table.*

### 3. Launch the Web Application Frontend Portal
Open a separate, second PowerShell tab, navigate to the frontend asset folder, and launch a lightweight web server:
```powershell
cd frontend
python -m http.server 3000
```

### 4. Run the Evaluation Simulation
1. Launch any modern browser and navigate to: **`http://localhost:3000`**
2. Input a customer name, select multiple menu dishes, and press **Submit Order & Pay**.
3. The app executes an instant REST call over port `8080`, pipes transactions over Kafka, and immediately shifts your screen onto a **Live Delivery Timeline Tracking** view.
4. Open **MongoDB Compass** (`mongodb://localhost:27017`) and refresh the screen to watch all 7 decoupled databases create and populate records independently!

