import ballerinax/kafka;

configurable string kafkaBootstrap = "localhost:9092";

listener kafka:Listener platformListener = new (kafkaBootstrap, {
    groupId: "order-service-group",
    topics: ["payments.completed", "payments.failed", "restaurant.accepted", "restaurant.rejected", "delivery.updated"],
    offsetReset: "earliest"
});

service on platformListener {
    remote function onConsumerRecord(kafka:Caller caller, anydata[] records) returns error? {
        foreach var rec in records {
            map<anydata> consumerRecord = <map<anydata>>rec;
            byte[] valueBytes = <byte[]>consumerRecord["value"];
            string topicName = consumerRecord["topic"].toString();
            
            string rawPayload = check string:fromBytes(valueBytes);
            json event = check rawPayload.fromJsonString();
            string orderId = check event.orderId;

            if topicName == "payments.completed" {
                check updateOrderStatus(orderId, CONFIRMED);
            } else if topicName == "payments.failed" || topicName == "restaurant.rejected" {
                check updateOrderStatus(orderId, CANCELLED);
            } else if topicName == "restaurant.accepted" {
                check updateOrderStatus(orderId, PREPARING);
            } else if topicName == "delivery.updated" {
                string statusText = check event.status;
                if statusText == "PICKED_UP" {
                    check updateOrderStatus(orderId, DELIVERING);
                } else if statusText == "COMPLETED" {
                    check updateOrderStatus(orderId, DELIVERED);
                }
            }
        }
        check caller->commit(); 
    }
}
