import ballerina/http;
import ballerina/io;
import ballerinax/kafka;

public function main() returns error? {
    io:println("=== PAYMENT SERVICE CLI CLIENT ===");

    // 1. Simulate Order Service emitting 'orders.created' to Kafka
    kafka:Producer kafkaProducer = check new (kafka:DEFAULT_URL);
    
    // Uses OrderCreatedEvent defined in payment_service.bal
    OrderCreatedEvent sampleOrder = {
        orderId: "ORD-9901",
        customerId: "CUST-505",
        totalAmount: 250.50d
    };

    check kafkaProducer->send({
        topic: "orders.created",
        value: sampleOrder.toJsonString().toBytes()
    });
    io:println("[CLIENT] Emitted sample 'orders.created' event for Order ID: ", sampleOrder.orderId);

    // Give backend service time to process event and persist to MongoDB
    io:println("[CLIENT] Waiting for Payment Service transaction processing...");
    
    // 2. Query Payment Transaction Status via REST API
    http:Client paymentRestApi = check new ("http://localhost:8084/payments");
    
    // Uses PaymentTransaction defined in payment_service.bal
    PaymentTransaction|error response = paymentRestApi->/transactions/[sampleOrder.orderId];
    if response is PaymentTransaction {
        io:println("\n--- Transaction Record Found ---");
        io:println("Transaction ID: ", response.transactionId);
        io:println("Order ID:       ", response.orderId);
        io:println("Amount:         N$", response.amount);
        io:println("Status:         ", response.status);
    } else {
        io:println("\n[CLIENT] Query result: ", response.message());
    }
}