import ballerina/http;
import ballerina/io;
import ballerinax/kafka;

public function main() returns error? {
    io:println("=== DELIVERY SERVICE CLI CLIENT ===");

    http:Client deliveryRestApi = check new ("http://localhost:8085/delivery");
    kafka:Producer kafkaProducer = check new (kafka:DEFAULT_URL);

    // 1. Register a new courier driver profile
    Driver newDriver = {
        driverId: "DRV-101",
        name: "John Doe",
        phone: "+264811234567",
        isAvailable: true,
        currentZone: "Windhoek Central"
    };

    http:Response regRes = check deliveryRestApi->/drivers.post(newDriver);
    io:println("[CLIENT] Registered Driver Response Code: ", regRes.statusCode);

    // 2. Simulate Restaurant Service emitting event
    RestaurantAcceptedEvent acceptedOrder = {
        orderId: "ORD-9901",
        restaurantId: "REST-301",
        deliveryAddress: "13 Jackson Kaujeua Street, Windhoek"
    };

    check kafkaProducer->send({
        topic: "restaurant.accepted",
        value: acceptedOrder.toJsonString().toBytes()
    });
    io:println("[CLIENT] Emitted 'restaurant.accepted' event for Order: ", acceptedOrder.orderId);

    // 3. Driver updates delivery progress and coordinates
    string targetDeliveryId = "DEL-" + acceptedOrder.orderId;
    
    // Inline record payload avoids needing a named 'LocationUpdate' type definition
    record { string status; string coordinates; } updatePayload = {
        status: "IN_TRANSIT",
        coordinates: "-22.5601, 17.0850"
    };

    http:Response updateRes = check deliveryRestApi->/track/[targetDeliveryId].put(updatePayload);
    io:println("[CLIENT] Updated Delivery Status Response Code: ", updateRes.statusCode);

    // 4. Query real-time tracking status
    DeliveryAssignment trackingInfo = check deliveryRestApi->/track/[acceptedOrder.orderId];
    io:println("\n--- Real-Time Delivery Tracking ---");
    io:println("Delivery ID:  ", trackingInfo.deliveryId);
    io:println("Order ID:     ", trackingInfo.orderId);
    io:println("Driver ID:    ", trackingInfo.driverId);
    io:println("Status:       ", trackingInfo.status);
    io:println("Coordinates:  ", trackingInfo.currentCoordinates);
}