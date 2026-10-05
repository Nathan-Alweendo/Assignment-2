import ballerina/http;
import ballerinax/kafka;
import ballerinax/mongodb;

configurable string kafkaUrl = "localhost:9092";
configurable string mongoUrl = "mongodb://localhost:27017";

type OpeningHours record {| string open; string close; |};
type OrderItem record {| string itemId; int quantity; |};

type Restaurant record {|
    readonly string restaurantId;
    string name;
    string address;
    map<OpeningHours> openingHours;
|};

type MenuItem record {|
    readonly string itemId;
    string restaurantId;
    string name;
    decimal price;
    int stock;
|};

type NewMenuItem record {|
    string itemId;
    string name;
    decimal price;
    int stock;
|};

type StockUpdate record {|
    int stock;
|};

type OrderCreated record {|
    string orderId;
    string restaurantId;
    OrderItem[] items;
|};

type OrderResult record {|
    string orderId;
    string reason?;
|};

//In-memory storage
table<Restaurant> key(restaurantId) restaurants = table [];
table<MenuItem> key(itemId) menuItems = table [];

//MongoDB
final mongodb:Client mongoClient = check new ({connection: mongoUrl});

function getCollection(string name) returns mongodb:Collection|error {
    mongodb:Database db = check mongoClient->getDatabase("restaurant_db");
    return db->getCollection(name);
}

// Runs once at startup: reload saved data into memory
function init() returns error? {
    mongodb:Collection rc = check getCollection("restaurants");
    stream<Restaurant, error?> rs = check rc->find({}, projection = {_id: 0}, targetType = Restaurant);
    check from Restaurant r in rs do {
        restaurants.add(r);
    };

    mongodb:Collection mc = check getCollection("menu_items");
    stream<MenuItem, error?> ms = check mc->find({}, projection = {_id: 0}, targetType = MenuItem);
    check from MenuItem m in ms do {
        menuItems.add(m);
    };
}

function saveRestaurant(Restaurant r) returns error? {
    mongodb:Collection col = check getCollection("restaurants");
    check col->insertOne(r);
}

function saveHours(string id, map<OpeningHours> hours) returns error? {
    mongodb:Collection col = check getCollection("restaurants");
    _ = check col->updateOne({restaurantId: id}, {set: {openingHours: hours}});
}

function saveMenuItem(MenuItem item) returns error? {
    mongodb:Collection col = check getCollection("menu_items");
    check col->insertOne(item);
}

function saveStock(string itemId, int stock) {
    mongodb:Collection|error col = getCollection("menu_items");
    if col is mongodb:Collection {
        mongodb:UpdateResult|error r = col->updateOne({itemId: itemId}, {set: {stock: stock}});
        if r is error {
            // log and carry on; memory is still correct
        }
    }
}

//Kafka producer
kafka:ProducerConfiguration producerConfig = {
    clientId: "restaurant-service",
    acks: "all",
    retryCount: 3
};
final kafka:Producer producer = check new (kafkaUrl, producerConfig);

//REST API
service /restaurants on new http:Listener(9091) {

    resource function get .() returns Restaurant[] {
        return restaurants.toArray();
    }

    resource function post .(Restaurant restaurant) returns Restaurant|http:Conflict|error {
        if restaurants.hasKey(restaurant.restaurantId) {
            return http:CONFLICT;
        }
        restaurants.add(restaurant);
        check saveRestaurant(restaurant);
        return restaurant;
    }

    resource function get [string id]() returns Restaurant|http:NotFound {
        Restaurant? found = restaurants[id];
        if found is () {
            return http:NOT_FOUND;
        }
        return found;
    }

    resource function put [string id]/hours(map<OpeningHours> newHours) returns Restaurant|http:NotFound|error {
        Restaurant? found = restaurants[id];
        if found is () {
            return http:NOT_FOUND;
        }
        found.openingHours = newHours;
        check saveHours(id, newHours);
        return found;
    }

    resource function post [string id]/menu(NewMenuItem newItem) returns MenuItem|http:NotFound|http:Conflict|http:BadRequest|error {
        if !restaurants.hasKey(id) {
            return http:NOT_FOUND;
        }
        if menuItems.hasKey(newItem.itemId) {
            return http:CONFLICT;
        }
        if newItem.price < 0d || newItem.stock < 0 {
            return http:BAD_REQUEST;
        }
        MenuItem item = {
            itemId: newItem.itemId,
            restaurantId: id,
            name: newItem.name,
            price: newItem.price,
            stock: newItem.stock
        };
        menuItems.add(item);
        check saveMenuItem(item);
        return item;
    }

    resource function get [string id]/menu() returns MenuItem[]|http:NotFound {
        if !restaurants.hasKey(id) {
            return http:NOT_FOUND;
        }
        return from MenuItem item in menuItems
            where item.restaurantId == id
            select item;
    }

    resource function patch [string id]/menu/[string itemId]/stock(StockUpdate update) returns MenuItem|http:NotFound|http:BadRequest {
        MenuItem? item = menuItems[itemId];
        if item is () || item.restaurantId != id {
            return http:NOT_FOUND;
        }
        if update.stock < 0 {
            return http:BAD_REQUEST;
        }
        item.stock = update.stock;
        saveStock(itemId, item.stock);
        return item;
    }
}

//Kafka consumer
kafka:ConsumerConfiguration consumerConfig = {
    groupId: "restaurant-service-group",
    topics: ["orders.created"],
    offsetReset: kafka:OFFSET_RESET_EARLIEST
};

service on new kafka:Listener(kafkaUrl, consumerConfig) {

    remote function onConsumerRecord(OrderCreated[] orders) returns error? {
        foreach OrderCreated o in orders {
            string? problem = reserveStock(o);
            if problem is () {
                OrderResult result = {orderId: o.orderId};
                check producer->send({
                    topic: "restaurant.order.accepted",
                    value: result.toJsonString().toBytes()
                });
            } else {
                OrderResult result = {orderId: o.orderId, reason: problem};
                check producer->send({
                    topic: "restaurant.order.rejected",
                    value: result.toJsonString().toBytes()
                });
            }
        }
    }
}

// Returns () on success, or a reason string on failure.
function reserveStock(OrderCreated o) returns string? {
    if !restaurants.hasKey(o.restaurantId) {
        return "Restaurant not found";
    }
    // First pass: check everything before changing anything
    foreach OrderItem line in o.items {
        if line.quantity <= 0 {
            return "Invalid quantity for: " + line.itemId;
        }
        MenuItem? item = menuItems[line.itemId];
        if item is () || item.restaurantId != o.restaurantId {
            return "Item not found: " + line.itemId;
        }
        if item.stock < line.quantity {
            return "Out of stock: " + item.name;
        }
    }
    // Second pass: deduct stock and save it
    foreach OrderItem line in o.items {
        MenuItem? item = menuItems[line.itemId];
        if item is MenuItem {
            item.stock -= line.quantity;
            saveStock(line.itemId, item.stock);
        }
    }
    return ();
}