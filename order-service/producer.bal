import ballerinax/kafka;

// No duplicate declaration here - uses the global variable from listener.bal
final kafka:Producer orderProducer = check new (kafkaBootstrap, {
    clientId: "order-service-producer",
    acks: "all",
    retryCount: 3
});

function publishOrderCreated(FoodOrder o) returns error? {
    json payload = o.toJson();
    check orderProducer->send({
        topic: "orders.created",
        key: o.orderId.toBytes(),
        value: payload.toJsonString().toBytes()
    });
}
