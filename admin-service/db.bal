import ballerinax/mongodb;
import ballerina/time;

configurable string mongoUrl = "mongodb://localhost:27017";

final mongodb:Client mongoClient = check new ({connection: mongoUrl});

function getMetricsCollection() returns mongodb:Collection|error {
    mongodb:Database adminDb = check mongoClient->getDatabase("admin_db");
    return adminDb->getCollection("metrics");
}

function initializeMetricsIfAbsent() returns error? {
    mongodb:Collection metrics = check getMetricsCollection();
    stream<PlatformMetrics, error?> result =
        check metrics->find({"metricId": "GLOBAL_METRICS"});
    var first = check result.next();
    check result.close();

    if first is () {
        PlatformMetrics initialMetrics = {
            metricId: "GLOBAL_METRICS",
            totalRevenue: 0.0,
            totalOrdersCount: 0,
            cancelledOrdersCount: 0,
            lastUpdatedAt: time:utcToString(time:utcNow())
        };
        check metrics->insertOne(initialMetrics);
    }
}

function recordNewSale(decimal amount) returns error? {
    check initializeMetricsIfAbsent();
    mongodb:Collection metrics = check getMetricsCollection();
    mongodb:Update update = {
        inc: {"totalRevenue": <float>amount, "totalOrdersCount": 1},
        set: {"lastUpdatedAt": time:utcToString(time:utcNow())}
    };
    _ = check metrics->updateOne({"metricId": "GLOBAL_METRICS"}, update);
}

function recordCancellation() returns error? {
    check initializeMetricsIfAbsent();
    mongodb:Collection metrics = check getMetricsCollection();
    mongodb:Update update = {
        inc: {"cancelledOrdersCount": 1},
        set: {"lastUpdatedAt": time:utcToString(time:utcNow())}
    };
    _ = check metrics->updateOne({"metricId": "GLOBAL_METRICS"}, update);
}

function fetchCurrentMetrics() returns PlatformMetrics|error {
    check initializeMetricsIfAbsent();
    mongodb:Collection metrics = check getMetricsCollection();
    stream<PlatformMetrics, error?> result =
        check metrics->find({"metricId": "GLOBAL_METRICS"});
    var first = check result.next();
    check result.close();

    if first is () {
        return error("Metrics tracking initialization failed");
    }
    return first.value;
}