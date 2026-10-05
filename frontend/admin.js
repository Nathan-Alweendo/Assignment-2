document.addEventListener("DOMContentLoaded", () => {
    const refreshBtn = document.getElementById("refresh-metrics-btn");

    async function fetchSystemMetrics() {
        try {
            const res = await fetch("http://localhost:8081/admin/metrics");
            const data = await res.json();

            document.getElementById("metric-revenue").innerText = `N$ ${data.total_revenue.toFixed(2)}`;
            document.getElementById("metric-orders").innerText = data.total_orders;
            document.getElementById("metric-cancellations").innerText = data.total_cancellations;
            document.getElementById("metric-ratio").innerText = `${data.cancellation_ratio_percentage.toFixed(1)}%`;
        } catch (err) {
            console.log("Admin service is warm or awaiting initial event streaming packets.");
        }
    }

    refreshBtn.addEventListener("click", fetchSystemMetrics);
    fetchSystemMetrics(); // Trigger loading lookups instantly
});
