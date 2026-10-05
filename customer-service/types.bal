import ballerina/time;

public type Address record {|
    string street;
    string city;
    string postalCode;
|};

public type Customer record {|
    readonly string id;
    string name;
    string email;
    string phone;
    Address[] addresses;
    time:Utc createdAt;
|};

public type CreateCustomerRequest record {|
    string id;
    string name;
    string email;
    string phone;
    Address[] addresses;
|};