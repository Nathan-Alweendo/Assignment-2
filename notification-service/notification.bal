import ballerina/io;

public function sendNotification(NotificationEvent event, string message) {
    io:println("========================================");
    io:println("         SIMULATED NOTIFICATION");
    io:println("========================================");
    io:println("Customer ID: " + event.customerId);
    io:println("Phone: " + event.phone);
    io:println("Email: " + event.email);
    io:println("Message: " + message);
    io:println("========================================");
}

public function processNotification(NotificationEvent event) {
    string message;

    match event.eventType {
        "ORDER_CREATED" => {
            message = "Your order " + event.orderId + " has been received.";
        }

        "PAYMENT_COMPLETED" => {
            message = "Payment for order " + event.orderId + " was successful.";
        }

        "PAYMENT_FAILED" => {
            string reason = event.reason ?: "Unknown";
            message = "Payment for order " + event.orderId +
                " failed. Reason: " + reason;
        }

        "DELIVERY_ASSIGNED" => {
            string driver = event.driverName ?: "a driver";
            message = "Your order " + event.orderId +
                " has been assigned to driver " + driver + ".";
        }

        "DELIVERY_COMPLETED" => {
            message = "Your order " + event.orderId +
                " has been delivered successfully.";
        }

        "ORDER_CANCELLED" => {
            message = "Your order " + event.orderId + " has been cancelled.";
        }

        _ => {
            message = "There is an update regarding your order " +
                event.orderId + ".";
        }
    }

    sendNotification(event, message);
}