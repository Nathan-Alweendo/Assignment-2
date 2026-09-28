import ballerina/http;
import ballerina/uuid;
import ballerina/time;

// Expose the REST API on public port 8080
service /orders on new http:Listener(8080) {

    // POST Endpoint: Accepts incoming customer checkout payloads
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

    // GET Endpoint: Allows users or frontends to poll their order status by ID
    resource function get [string orderId]() returns FoodOrder|http:NotFound|error {
        FoodOrder? targetOrder = check findOrder(orderId);
        if targetOrder is () {
            return http:NOT_FOUND;
        }
        return targetOrder;
    }
}
