# Kafka Event Registry — DSA612S Assignment 2

This contract defines the events shared across the platform. Do not alter topic names or payloads without a team review.

## Topic Schema Matrix

| Topic Name | Producer Service | Main Consumer Services | Key (Ordering) |
| :--- | :--- | :--- | :--- |
| `orders.created` | Order Service | Payment Service, Admin Service | `orderId` |
| `payments.completed` | Payment Service | Order Service, Notification Service | `orderId` |
| `payments.failed` | Payment Service | Order Service, Notification Service | `orderId` |
| `restaurant.accepted` | Restaurant Service | Order Service, Delivery Service | `orderId` |
| `restaurant.rejected` | Restaurant Service | Order Service, Notification Service | `orderId` |
| `delivery.assigned` | Delivery Service | Order Service, Notification Service | `orderId` |
| `delivery.updated` | Delivery Service | Order Service, Customer Service | `orderId` |

## Service Database Assignments
Each service connects to the shared Mongo engine but must isolate its operations to its designated database:
* **Customer Service:** `mongodb://mongo:27017/customer_db`
* **Restaurant Service:** `mongodb://mongo:27017/restaurant_db`
* **Order Service:** `mongodb://mongo:27017/order_db`
* **Payment Service:** `mongodb://mongo:27017/payment_db`
* **Delivery Service:** `mongodb://mongo:27017/delivery_db`
* **Notification Service:** `mongodb://mongo:27017/notification_db`
* **Admin Service:** `mongodb://mongo:27017/admin_db`
