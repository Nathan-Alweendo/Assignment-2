import ballerinax/kafka;
import ballerina/io;

listener kafka:Listener notificationListener = new (kafka:DEFAULT_URL, {
    groupId: "notification-service-group",
    topics: [
        "orders.created",
        "payments.completed",
        "payments.failed",
        "delivery.assigned",
        "delivery.completed",
        "orders.cancelled"
    ]
});

service on notificationListener {

    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord event in records {
            io:println("========================================");
            io:println("        KAFKA EVENT RECEIVED");
            io:println("========================================");

            string eventData = check string:fromBytes(event.value);

            io:println("Event data: " + eventData);

            json|error eventJson = eventData.fromJsonString();

            if eventJson is json {
                NotificationEvent|error notificationEvent =
                    eventJson.cloneWithType();

                if notificationEvent is NotificationEvent {
                    processNotification(notificationEvent);
                } else {
                    io:println("ERROR: Invalid notification event.");
                }
            } else {
                io:println("ERROR: Invalid JSON event.");
            }

            io:println("========================================");
        }
    }
}

public function main() {
    io:println("Notification Service started.");
    io:println("Waiting for Kafka events...");
}