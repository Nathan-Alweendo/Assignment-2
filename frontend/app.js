document.addEventListener("DOMContentLoaded", () => {
    const orderForm = document.getElementById("order-form");

    // Enforce a strict safeguard check: only execute if the checkout form exists on the current page
    if (!orderForm) return;

    orderForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        
        const customerName = document.getElementById("customerName").value;
        const generatedCustomerId = "cust-" + Math.floor(1000 + Math.random() * 9000);

        const items = [];
        if (document.getElementById("item1").checked) {
            items.push({
                itemId: document.getElementById("item1").value,
                name: document.getElementById("item1").dataset.name,
                quantity: parseInt(document.getElementById("qty1").value),
                price: parseFloat(document.getElementById("item1").dataset.price)
            });
        }
        if (document.getElementById("item2").checked) {
            items.push({
                itemId: document.getElementById("item2").value,
                name: document.getElementById("item2").dataset.name,
                quantity: parseInt(document.getElementById("qty2").value),
                price: parseFloat(document.getElementById("item2").dataset.price)
            });
        }

        const payload = {
            customerId: generatedCustomerId,
            restaurantId: document.getElementById("restaurantId").value,
            deliveryAddress: document.getElementById("deliveryAddress").value,
            items: items
        };

        try {
            const res = await fetch("http://localhost:8080/orders", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload)
            });
            const data = await res.json();
            
            // Stash variables inside the client cache layer cleanly
            localStorage.setItem("currentOrderData", JSON.stringify(data));
            localStorage.setItem("clientName", customerName);
            
            // Redirect smoothly to the separate visual courier timeline page
            window.location.href = "tracking.html";
        } catch (err) {
            alert("Error communicating with order-service (Is it running?)");
            console.error(err);
        }
    });
});
