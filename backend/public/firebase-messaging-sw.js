// Import Firebase scripts (required for background notifications)
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

(async () => {
  try {
    const response = await fetch('/admin/firebase-config');
    const firebaseConfig = await response.json();

    console.log('✅ Firebase Config loaded:', firebaseConfig);

    firebase.initializeApp(firebaseConfig);
    const messaging = firebase.messaging();

    messaging.onBackgroundMessage((payload) => {
      console.log('[firebase-messaging-sw.js] Received background message:', payload);

      const { title, body } = payload.notification;

      self.registration.showNotification(title, { body });

      self.registration.showNotification(title, {
        body,
        icon: '/images/notification-icon.png', 
      });
    });

  } catch (error) {
    console.error('❌ Failed to initialize Firebase Messaging:', error);
  }
})();
