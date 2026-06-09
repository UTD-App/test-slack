
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

            await fetch("/superadmin/save-fcm-token", {
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
            // showNotificationAlert();
        }
    }
}

function showNotificationAlert() {
    if (document.getElementById("notification-alert")) return;

    const lang = getLanguage();
    const text = {
        ar: {
            message: "⚠️ يرجى تفعيل الإشعارات للحصول على التحديثات.",
            button: "تفعيل الإشعارات"
        },
        en: {
            message: "⚠️ Please enable notifications to receive updates.",
            button: "Enable Notifications"
        }
    };

    const notificationContainer = document.createElement("div");
    notificationContainer.id = "notification-alert";
    notificationContainer.style.position = "fixed";
    notificationContainer.style.top = "10px"; // أعلى الصفحة
    notificationContainer.style.left = "14%";
    notificationContainer.style.transform = "translateX(-50%)";
    notificationContainer.style.background = "#ffcc00";
    notificationContainer.style.padding = "15px";
    notificationContainer.style.borderRadius = "10px";
    notificationContainer.style.boxShadow = "0px 4px 10px rgba(0,0,0,0.2)";
    notificationContainer.style.zIndex = "99999"; // فوق جميع العناصر
    notificationContainer.style.textAlign = "center";
    notificationContainer.style.width = "auto";
    notificationContainer.style.minWidth = "300px";
    notificationContainer.dir = lang === "ar" ? "rtl" : "ltr"; // اتجاه النص

    notificationContainer.innerHTML = `
        <p style="margin: 0; font-weight: bold;">${text[lang].message}</p>
        <button id="enable-notifications" style="margin-top: 8px; background: #007bff; color: #fff; border: none; padding: 10px 15px; border-radius: 5px; cursor: pointer;">
            ${text[lang].button}
        </button>
    `;
    document.body.appendChild(notificationContainer);

    document.getElementById("enable-notifications").addEventListener("click", () => {
        Notification.requestPermission().then(permission => {
            console.log("Notification Permission: ", permission);
            if (permission === "granted") {
                console.log("✅ الإشعارات مفعلة.");
                notificationContainer.remove();
            } else {
                console.warn("❌ تم رفض الإشعارات.");
            }
        }).catch(error => {
            console.error("⚠️ خطأ أثناء طلب الإذن للإشعارات:", error);
        });
    });
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


