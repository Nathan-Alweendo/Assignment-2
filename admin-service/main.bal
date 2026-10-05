import ballerina/http;

service /admin on new http:Listener(8081) { // Running on port 8081 to avoid conflicts

    # GET Endpoint: Calculates and returns live system performance parameters
    resource function get metrics() returns json|error {
        PlatformMetrics m = check fetchCurrentMetrics();
        
        // Calculate ratio values safely to avoid division by zero
        decimal cancellationRatio = 0.0;
        if m.totalOrdersCount > 0 {
            cancellationRatio = (<decimal>m.cancelledOrdersCount / <decimal>m.totalOrdersCount) * 100.0;
        }

        return {
            total_revenue: m.totalRevenue,
            total_orders: m.totalOrdersCount,
            total_cancellations: m.cancelledOrdersCount,
            cancellation_ratio_percentage: cancellationRatio,
            last_synchronized: m.lastUpdatedAt
        };
    }
}
