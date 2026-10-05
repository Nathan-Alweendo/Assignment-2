import ballerina/http;
import ballerina/io;
import ballerinax/kafka;
import ballerinax/mongodb;

// Models
public type Driver record {
    string driverId;
    string name;
    string phone;
    boolean isAvailable;
    string currentZone;
};

public type DeliveryAssignment record {
    string deliveryId;
    string orderId;
    string restaurantId;
    string driverId;
    string status; // ASSIGNED, PICKED_UP, IN_TRANSIT, DELIVERED
    string currentCoordinates;
};

public type RestaurantAcceptedEvent record {
    string orderId;
    string restaurantId;
    string deliveryAddress;
};

public type DeliveryEvent record {
    string deliveryId;
    string orderId;
    string driverId;
    string status;
    string locationCoordinates;
};

// Global variables declared at module scope without top-level client actions
final mongodb:Client mongoClient;
final mongodb:Database deliveryDb;
final mongodb:Collection deliveryColl;
final mongodb:Collection driverColl;
final kafka:Producer kafkaProducer;

// Initialize clients and collections inside the init() function
function init() returns error? {
    mongoClient = check new ({
        connection: "mongodb://mongo:27017"
    });
    deliveryDb = check mongoClient->getDatabase("delivery_db");
    deliveryColl = check deliveryDb->getCollection("deliveries");
    driverColl = check deliveryDb->getCollection("drivers");
    kafkaProducer = check new (kafka:DEFAULT_URL);
}

// Kafka Listener Setup
listener kafka:Listener kafkaListener = new (kafka:DEFAULT_URL, {
    groupId: "delivery-group",
    topics: ["restaurant.accepted"]
});

service on kafkaListener {
    remote function onConsumerRecord(kafka:Caller caller, kafka:BytesConsumerRecord[] records) returns error? {
        foreach var recordVal in records {
            string payloadStr = check string:fromBytes(recordVal.value);
            RestaurantAcceptedEvent restEvent = check payloadStr.fromJsonStringWithType();

            io:println("[Delivery Service] Received accepted order for dispatch: ", restEvent.orderId);

            // Match available driver from MongoDB
            map<json> filter = {"isAvailable": true};
            stream<Driver, error?> driverStream = check driverColl->find(filter);
            record {| Driver value; |}? matchedDriver = check driverStream.next();
            check driverStream.close();

            string assignedDriverId = "DRIVER-DEFAULT-01";
            if matchedDriver is record {| Driver value; |} {
                assignedDriverId = matchedDriver.value.driverId;
            }

            string delId = "DEL-" + restEvent.orderId;
            DeliveryAssignment delivery = {
                deliveryId: delId,
                orderId: restEvent.orderId,
                restaurantId: restEvent.restaurantId,
                driverId: assignedDriverId,
                status: "ASSIGNED",
                currentCoordinates: "-22.5594, 17.0832"
            };

            check deliveryColl->insertOne(delivery);

            // Emit 'delivery.assigned' event to Kafka
            DeliveryEvent assignedEvent = {
                deliveryId: delId,
                orderId: restEvent.orderId,
                driverId: assignedDriverId,
                status: "ASSIGNED",
                locationCoordinates: delivery.currentCoordinates
            };

            check kafkaProducer->send({
                topic: "delivery.assigned",
                value: assignedEvent.toJsonString().toBytes()
            });

            io:println("[Delivery Service] Driver ", assignedDriverId, " assigned to Order ", restEvent.orderId);
        }
    }
}

// REST API for Courier Shifts & Real-time Tracking
service /delivery on new http:Listener(8085) {

    resource function post drivers(@http:Payload Driver driver) returns http:Created|error {
        check driverColl->insertOne(driver);
        return http:CREATED;
    }

    resource function put track/[string deliveryId](string status, string coordinates) returns http:Ok|http:NotFound|error {
        map<json> filter = {"deliveryId": deliveryId};
        
        // Correct mongodb:Update record structure for updateOne
        mongodb:Update updateOp = {
            set: {
                "status": status,
                "currentCoordinates": coordinates
            }
        };

        mongodb:UpdateResult _ = check deliveryColl->updateOne(filter, updateOp);

        // Fetch updated document
        stream<DeliveryAssignment, error?> delStream = check deliveryColl->find(filter);
        record {| DeliveryAssignment value; |}? res = check delStream.next();
        check delStream.close();

        if res is record {| DeliveryAssignment value; |} {
            DeliveryEvent updateEvent = {
                deliveryId: deliveryId,
                orderId: res.value.orderId,
                driverId: res.value.driverId,
                status: status,
                locationCoordinates: coordinates
            };

            check kafkaProducer->send({
                topic: "delivery.updated",
                value: updateEvent.toJsonString().toBytes()
            });

            return http:OK;
        }

        return http:NOT_FOUND;
    }

    resource function get track/[string orderId]() returns DeliveryAssignment|http:NotFound|error {
        map<json> filter = {"orderId": orderId};
        stream<DeliveryAssignment, error?> delStream = check deliveryColl->find(filter);
        record {| DeliveryAssignment value; |}? res = check delStream.next();
        check delStream.close();

        if res is record {| DeliveryAssignment value; |} {
            return res.value;
        }
        return http:NOT_FOUND;
    }
}