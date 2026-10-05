import ballerinax/mongodb;

configurable string mongoUrl = "mongodb://localhost:27017/order_db";

final mongodb:Client mongoClient = check new ({
    connection: {
        url: mongoUrl
    }
});

// Saves a new order into the database
function saveOrder(FoodOrder o) returns error? {
    map<json> doc = <map<json>>o.toJson();
    check mongoClient->insert(doc, "orders", "order_db");
}

// Updates the status of an existing order
function updateOrderStatus(string orderId, OrderStatus status) returns error? {
    map<json> filter = { "orderId": orderId };
    map<json> update = { 
        "$set": { 
            "status": status.toString()
        } 
    };
    _ = check mongoClient->update(update, "orders", "order_db", filter, upsert = false);
}

// Finds a specific order by ID
function findOrder(string orderId) returns FoodOrder?|error {
    map<json> filter = { "orderId": orderId };
    
    // Using a plain map descriptor variable clears out the token parsing bug
    map<json> findOptions = {};
    stream<record {| anydata...; |}, error?> result = check mongoClient->find("order_db", "orders", filter, findOptions);
    record {| record {| anydata...; |} value; |}? first = check result.next();
    
    if first is () {
        return ();
    } else {
        FoodOrder convertedOrder = check first.value.cloneWithType(FoodOrder);
        return convertedOrder;
    }
}
