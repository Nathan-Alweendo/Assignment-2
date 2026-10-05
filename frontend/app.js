document.addEventListener("DOMContentLoaded", () => {
    const orderForm = document.getElementById("order-form");

    if (!orderForm) return;

    orderForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        
        const customerName = document.getElementById("customerName").value;
        const generatedCustomerId = "cust-" + Math.floor(1000 + Math.random() * 9000);

        // COMPREHENSIVE LOOP FOR ALL 7 MENU ITEMS
        const items = [];
        const maxItems = 7;
        
        for (let i = 1; i <= maxItems; i++) {
            const checkbox = document.getElementById(`item${i}`);
            const qtyInput = document.getElementById(`qty${i}`);
            
            if (checkbox && checkbox.checked) {
                items.push({
                    itemId: checkbox.value,
                    name: checkbox.dataset.name,
                    quantity: parseInt(qtyInput.value),
                    price: parseFloat(checkbox.dataset.price)
                });
            }
        }

        // Prevent empty order forms from triggering network request pipelines
        if (items.length === 0) {
            alert("Please select at least one menu item before submitting checkout!");
            return;
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
            
            localStorage.setItem("currentOrderData", JSON.stringify(data));
            localStorage.setItem("clientName", customerName);
            
            window.location.href = "tracking.html";
        } catch (err) {
            alert("Error communicating with order-service (Is it running?)");
            console.error(err);
        }
    });
});
