import ballerinax/mongodb;
import ballerina/log;

// Connects to mongodb://mongo:27017/customer_db as per requirements
final mongodb:Client mongoDb = check new ({
    connection: "mongodb://mongo:27017"
});

final string DATABASE_NAME = "customer_db";
final string COLLECTION_NAME = "customers";

public function createCustomerInDb(Customer customer) returns error? {
    mongodb:Database db = check mongoDb->getDatabase(DATABASE_NAME);
    mongodb:Collection customers = check db->getCollection(COLLECTION_NAME);
    check customers->insertOne(customer);
    log:printInfo("Customer profile created in database: " + customer.id);
}

public function getCustomerFromDb(string customerId) returns Customer|error {
    mongodb:Database db = check mongoDb->getDatabase(DATABASE_NAME);
    mongodb:Collection customers = check db->getCollection(COLLECTION_NAME);
    
    record {}|error? result = customers->findOne({id: customerId});
    if result is record {} {
        return check result.cloneWithType(Customer);
    }
    return error("Customer not found with ID: " + customerId);
}

public function updateCustomerAddressInDb(string customerId, Address[] addresses) returns error? {
    mongodb:Database db = check mongoDb->getDatabase(DATABASE_NAME);
    mongodb:Collection customers = check db->getCollection(COLLECTION_NAME);
    
    _ = check customers->updateOne(
        {id: customerId},
        {"$set": {"addresses": addresses}}
    );
    log:printInfo("Customer addresses updated for ID: " + customerId);
}