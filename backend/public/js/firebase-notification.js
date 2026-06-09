
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.2/firebase-app.js";
import { getMessaging, getToken, onMessage } from "https://www.gstatic.com/firebasejs/10.7.2/firebase-messaging.js";

const firebaseConfig = window.firebaseConfig;


const firebaseApp = initializeApp(firebaseConfig);
const messaging = getMessaging(firebaseApp);

async function requestPermission() {
    try {
        const permission = await Notification.requestPermission();
        if (permission === "granted") {
            console.log("Notification permission granted.");
            const token = await getToken(messaging, { vapidKey: firebaseConfig.vapidKey });

            await fetch("/admin/save-fcm-token", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-TOKEN": document.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify({ token })
            });
        } else {
            console.log("Unable to get permission for notifications.");

        }
    } catch (error) {
        console.error("Error getting permission for notifications:", error);
    }
}

document.addEventListener("DOMContentLoaded", () => {
    checkNotificationPermission();
});

function getLanguage() {
    const lang = navigator.language || navigator.userLanguage;
    return lang.startsWith("ar") ? "ar" : "en"; // تحديد اللغة بناءً على المتصفح
}

function checkNotificationPermission() {
    if (Notification.permission === "granted") {
        console.log("🔔 Notifications are already enabled.");
    } else if (Notification.permission === "denied" || Notification.permission === "default") {
        if (!document.getElementById("notification-alert")) {
        }
    }
}




onMessage(messaging, (payload) => {
    // if (sessionStorage.getItem("notificationSent") === "true") return;

    const click_action = payload.data.click_action || "https://default-url.com";
    const title = payload.notification.title;
    const body = payload.notification.body;

    const notification = new Notification(title, {
        body: body,
        icon: "/logo.png",
        data: { url: click_action }
    });

    notification.onclick = (event) => {
        event.preventDefault();
        window.open(notification.data.url, "_blank");
    };

    sessionStorage.setItem("notificationSent", "true");
});



document.addEventListener("DOMContentLoaded", () => {
    requestPermission();
});


