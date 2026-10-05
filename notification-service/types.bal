public type NotificationEvent record {|
    string eventType;
    string orderId;
    string customerId;
    string phone;
    string email;
    string? reason;
    string? driverName;
|};