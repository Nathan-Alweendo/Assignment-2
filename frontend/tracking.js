document.addEventListener("DOMContentLoaded", () => {
    const receiptData = document.getElementById("receipt-data");
    const clientNameDisplay = document.getElementById("display-client-name");
    const driverName = document.getElementById("driver-name");
    const driverStatus = document.getElementById("driver-status");

    // Pull item data logs from cache storage
    const rawOrderData = localStorage.getItem("currentOrderData");
    const savedClientName = localStorage.getItem("clientName");

    if (!rawOrderData) {
        receiptData.innerText = "No active checkout record found. Please drop an order first.";
        return;
    }

    const order = JSON.parse(rawOrderData);
    clientNameDisplay.innerText = savedClientName || "Customer";
    receiptData.innerText = JSON.stringify(order, null, 2);

    // Animate the timeline simulation loops
    document.getElementById('step-created').classList.add('active');
    driverName.innerText = "Processing System Verification...";
    driverStatus.innerText = "Broadcasting order.created payload to Kafka event stream...";

    setTimeout(() => {
        document.getElementById('step-created').className = 'timeline-step completed';
        document.getElementById('step-confirmed').classList.add('active');
        driverName.innerText = "Payment Gateway Authorized";
        driverStatus.innerText = "Consumed payments.completed event over port 9093. Status: CONFIRMED.";
    }, 2000);

    setTimeout(() => {
        document.getElementById('step-confirmed').className = 'timeline-step completed';
        document.getElementById('step-preparing').classList.add('active');
        driverName.innerText = "Restaurant Kitchen Service (Port 9091)";
        driverStatus.innerText = "Consumed restaurant.accepted event. Assembling menu items...";
    }, 4500);

    setTimeout(() => {
        document.getElementById('step-preparing').className = 'timeline-step completed';
        document.getElementById('step-delivering').classList.add('active');
        driverName.innerText = "Driver assigned: Johannes N. (🛵)";
        driverStatus.innerText = "Johannes has picked up packages from hub. En route to address...";
    }, 7000);

    setTimeout(() => {
        document.getElementById('step-delivering').className = 'timeline-step completed';
        document.getElementById('step-completed').classList.add('completed');
        driverStatus.innerText = "Delivered successfully via delivery-service (Port 9094)! Transaction closed.";
    }, 10000);
});
