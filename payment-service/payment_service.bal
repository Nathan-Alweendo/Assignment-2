import ballerina/http;
import ballerina/io;
import ballerinax/kafka;
import ballerinax/mongodb;

// Models
public type PaymentTransaction record {
    string transactionId;
    string orderId;
    string customerId;
    decimal amount;
    string status; // SUCCESS, FAILED
    string timestamp;
};

public type OrderCreatedEvent record {
    string orderId;
    string customerId;
    decimal totalAmount;
};

public type PaymentResultEvent record {
    string orderId;
    string transactionId;
    string status;
    decimal amount;
};

// Global variables declared without top-level action calls
final mongodb:Client mongoClient;
final mongodb:Database paymentDb;
final mongodb:Collection paymentColl;
final kafka:Producer kafkaProducer;

// Initialize clients and collections inside module init
function init() returns error? {
    mongoClient = check new ({
        connection: "mongodb://mongo:27017"
    });
    paymentDb = check mongoClient->getDatabase("payment_db");
    paymentColl = check paymentDb->getCollection("transactions");
    kafkaProducer = check new (kafka:DEFAULT_URL);
}

// Listener on 'orders.created' Kafka Topic
listener kafka:Listener kafkaListener = new (kafka:DEFAULT_URL, {
    groupId: "payment-group",
    topics: ["orders.created"]
});

service on kafkaListener {
    remote function onConsumerRecord(kafka:Caller caller, kafka:BytesConsumerRecord[] records) returns error? {
        foreach var recordVal in records {
            string payloadStr = check string:fromBytes(recordVal.value);
            OrderCreatedEvent orderEvent = check payloadStr.fromJsonStringWithType();

            io:println("[Payment Service] Processing payment for Order ID: ", orderEvent.orderId);

            boolean isSuccess = orderEvent.totalAmount > 0d;
            string status = isSuccess ? "SUCCESS" : "FAILED";
            string txId = "TXN-" + orderEvent.orderId;

            PaymentTransaction tx = {
                transactionId: txId,
                orderId: orderEvent.orderId,
                customerId: orderEvent.customerId,
                amount: orderEvent.totalAmount,
                status: status,
                timestamp: "2026-10-03T11:00:00Z"
            };

            // Save transaction to MongoDB
            check paymentColl->insertOne(tx);

            // Emit result event
            string targetTopic = isSuccess ? "payments.completed" : "payments.failed";
            PaymentResultEvent resultEvent = {
                orderId: orderEvent.orderId,
                transactionId: txId,
                status: status,
                amount: orderEvent.totalAmount
            };

            check kafkaProducer->send({
                topic: targetTopic,
                value: resultEvent.toJsonString().toBytes()
            });

            io:println("[Payment Service] Emitted event to topic '", targetTopic, "' for Order ID: ", orderEvent.orderId);
        }
    }
}

// REST API for Billing Queries
service /payments on new http:Listener(8084) {

    resource function get transactions/[string orderId]() returns PaymentTransaction|http:NotFound|error {
        map<json> filter = {"orderId": orderId};
        stream<PaymentTransaction, error?> resultStream = check paymentColl->find(filter);
        record {| PaymentTransaction value; |}? res = check resultStream.next();
        check resultStream.close();

        if res is record {| PaymentTransaction value; |} {
            return res.value;
        }
        return http:NOT_FOUND;
    }
}