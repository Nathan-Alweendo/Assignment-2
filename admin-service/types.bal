
// Individual order data payload from Kafka (matches order-service data contracts)
public type OrderItem record {
    string itemId;
    string name;
    int quantity;
    decimal price;
};

public type OrderCreatedPayload record {
    string orderId;
    string customerId;
    string restaurantId;
    OrderItem[] items;
    decimal totalAmount;
    string deliveryAddress;
    string status;
};

// Schema model for storing platform-wide metric summaries inside admin_db
public type PlatformMetrics record {|
    string metricId; // e.g., "GLOBAL_METRICS"
    decimal totalRevenue;
    int totalOrdersCount;
    int cancelledOrdersCount;
    string lastUpdatedAt;
|};
