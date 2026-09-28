import ballerina/time;

public enum OrderStatus {
    CREATED,
    CONFIRMED,
    PREPARING,
    DELIVERING,
    DELIVERED,
    CANCELLED
}

public type OrderItem record {|
    string itemId;
    string name;
    int quantity;
    decimal price;
|};

// Structure for incoming POST /orders requests
public type OrderRequest record {|
    string customerId;
    string restaurantId;
    OrderItem[] items;
    string deliveryAddress;
|};

// Full database document and event entity pattern
public type FoodOrder record {|
    readonly string orderId;
    string customerId;
    string restaurantId;
    OrderItem[] items;
    decimal totalAmount;
    string deliveryAddress;
    OrderStatus status;
    time:Utc createdAt;
    time:Utc updatedAt;
|};
