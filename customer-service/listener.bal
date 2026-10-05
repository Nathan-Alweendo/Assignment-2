import ballerinax/kafka;
import ballerina/log;

listener kafka:Listener kafkaListener = check new (kafka:DEFAULT_URL, {
    groupId: "customer-service-group",
    topics: ["delivery.updated"]
});

service on kafkaListener {
    remote function onConsumerRecord(kafka:BytesConsumerRecord[] records) returns error? {
        foreach var rec in records {
            string payload = check string:fromBytes(rec.value);
            log:printInfo("Received tracking update on 'delivery.updated': " + payload);
        }
    }
}