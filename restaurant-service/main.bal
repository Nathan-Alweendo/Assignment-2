import ballerina/http;

type OpeningHours record {| string open; string close; |};

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

table<Restaurant> key(restaurantId) restaurants = table [];
table<MenuItem> key(itemId) menuItems = table [];

service /restaurants on new http:Listener(9091){
    resource function get .() returns Restaurant[] {
        return restaurants.toArray();
    }

    resource function post .(Restaurant restaurant) returns Restaurant|http:Conflict{
        if restaurants.hasKey(restaurant.restaurantId) {
            return http:CONFLICT;
        }
        restaurants.add(restaurant);
        return restaurant;
    }

    resource function get [string id]() returns Restaurant|http:NotFound {
        Restaurant? found = restaurants[id];
        if found is () {
            return http:NOT_FOUND;
        }
        return found;
    }

    resource function put [string id]/hours(map<OpeningHours> newHours) returns Restaurant|http:NotFound {
        Restaurant? found = restaurants[id];
        if found is () {
            return http:NOT_FOUND;
        }
        found.openingHours = newHours;
        return found;
    }

    //check through this later
    resource function post [string id]/menu(NewMenuItem newItem) returns MenuItem|http:NotFound|http:Conflict|http:BadRequest {
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
        return item;
    }
}