import ballerina/log;
import ballerinax/kafka;

configurable string kafkaBootstrap = "localhost:9092";

listener kafka:Listener platformListener = new (kafkaBootstrap, {
    groupId: "admin-service-group",
    topics: ["orders.created", "payments.failed", "restaurant.rejected"],
    offsetReset: "earliest"
});

service on platformListener {
    remote function onConsumerRecord(kafka:Caller caller,
            kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord rec in records {
            error? result = processRecord(rec);
            if result is error {
                log:printError("Failed to process record", 'error = result);
            }
        }
        check caller->commit();
    }
}

function processRecord(kafka:BytesConsumerRecord rec) returns error? {
    string topicName = rec.offset.partition.topic;
    string rawPayload = check string:fromBytes(rec.value);
    json event = check rawPayload.fromJsonString();

    if topicName == "orders.created" {
        OrderCreatedPayload orderData = check event.cloneWithType();
        check recordNewSale(orderData.totalAmount);
    } else if topicName == "payments.failed" || topicName == "restaurant.rejected" {
        check recordCancellation();
    }
}