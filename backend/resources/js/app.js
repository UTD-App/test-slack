require('./bootstrap');

// import Vue from 'vue'
//
// Vue.config.productionTip = false
//
// Vue.component('test', require('./components/ExampleComponents.vue').default);
//
// //initialize vue
// const app = new Vue({
//     el: '#app',
// });

// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getMessaging, getToken, onMessage } from "firebase/messaging";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
    apiKey: "AIzaSyDuqgaX1O4_YQdYOUGNSbKnkm_ufDOtckw",
    authDomain: "sree3-54527.firebaseapp.com",
    projectId: "sree3-54527",
    storageBucket: "sree3-54527.appspot.com",
    messagingSenderId: "903070301917",
    appId: "1:903070301917:web:cc3e56e795355ebd0d2534",
    measurementId: "G-GFC8PH6N2G"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);


// Get registration token. Initially this makes a network call, once retrieved
// subsequent calls to getToken will return from cache.
const messaging = getMessaging();
onMessage(messaging, (payload) => {
    console.log('Message received. ', payload);
    // ...
});
getToken(messaging, { vapidKey: 'BMUJdEtRolJtxXjFR2XdIrVx99gpC4hoFr6WlfCreUF2aZ10fcEPc_aohogwcEWkzdq_N5xFavF01KXcqNh_6BY' }).then((currentToken) => {
    if (currentToken) {
        // Send the token to your server and update the UI if necessary
        console.log('current token is: ' + currentToken)
        // ...
    } else {
        // Show permission request UI
        console.log('No registration token available. Request permission to generate one.');
        // ...
    }
}).catch((err) => {
    console.log('An error occurred while retrieving token. ', err);
    // ...
});

document.addEventListener("DOMContentLoaded", function () {
    const table = document.querySelector('.table-responsive');
    if (document.documentElement.lang === "ar") {
        table.scrollLeft = table.scrollWidth;
    } else {
        table.scrollLeft = 0;
    }
});
