import ballerina/http;
import ballerina/uuid;
import ballerina/time;

// FIXED: Injected Cross-Origin Resource Sharing rules into the service configuration block
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service /orders on new http:Listener(8080) {

    # POST Endpoint: Accepts incoming customer checkout payloads
    # + req - The inbound structured object representation mapping out the selected dishes and coordinates
    # + return - The generated food order record summary complete with tracking identification metrics
    resource function post .(OrderRequest req) returns FoodOrder|error {
        // Calculate the subtotal cost dynamically across all items ordered
        decimal total = 0;
        foreach var item in req.items {
            total += item.price * item.quantity;
        }

        // Build a strict schema record document mapping
        FoodOrder newOrder = {
            orderId: uuid:createType4AsString(),
            customerId: req.customerId,
            restaurantId: req.restaurantId,
            items: req.items,
            totalAmount: total,
            deliveryAddress: req.deliveryAddress,
            status: CREATED,
            createdAt: time:utcNow(),
            updatedAt: time:utcNow()
        };

        // 1. Persist the record inside our private, isolated MongoDB cluster
        check saveOrder(newOrder);

        // 2. Broadcast an outbound event message over Kafka to alert other services
        check publishOrderCreated(newOrder);

        return newOrder;
    }

    # GET Endpoint: Allows users or frontends to poll their order status by ID
    # + orderId - The target tracking key generated during initial compilation processes
    # + return - The tracking metadata description, a NotFound instance code, or a processing exception
    resource function get [string orderId]() returns FoodOrder|http:NotFound|error {
        FoodOrder? targetOrder = check findOrder(orderId);
        if targetOrder is () {
            return http:NOT_FOUND;
        }
        return targetOrder;
    }
}
