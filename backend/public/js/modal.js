console.log('✅ notifications.js loaded');


document.addEventListener("DOMContentLoaded", function () {
    const notifCountEl = document.getElementById('notificationsCount');
    const notifContentEl = document.getElementById('notificationsContent');
    const closeBtn = document.getElementById('closeModalBtn');
    const markAllBtn = document.getElementById('markAllReadBtn');
    const modal = document.getElementById('myModal');
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    const api = window.NOTIFICATIONS_API;

    window.NotificationBus = {
        emit(eventName, detail = {}) {
            document.dispatchEvent(new CustomEvent(eventName, { detail }));
        },
        on(eventName, callback) {
            document.addEventListener(eventName, callback);
        }
    };

    const pusher = new Pusher(window.PUSHER_CONFIG.key, {
        cluster: window.PUSHER_CONFIG.options.cluster,
        forceTLS: window.PUSHER_CONFIG.options.useTLS
    });
    const adminType = window.ADMIN_TYPE
   
    const channel = pusher.subscribe('admin.notifications');
    channel.bind('AdminNotificationCreated', function (e) {

        if (adminType) return;
        console.log('oo',e);

        if (notifCountEl) {
                const current = parseInt(notifCountEl.textContent, 10) || 0;
                notifCountEl.style.display = 'inline';
                notifCountEl.textContent = current + 1;
            
        }

        if (notifContentEl) {
            const newNotif = `
                <div class="notification-item unread" data-id="${e.id}">
                    <div class="title">${e.title}</div>
                    <div class="message text-muted small">${e.message}</div>
                    <div class="time text-secondary small">الآن</div>
                    <button class="btn btn-sm btn-outline-primary mark-read-btn mt-1" data-id="${e.id}">
                        تحديد كمقروء
                    </button>
                </div>`;
            notifContentEl.insertAdjacentHTML('afterbegin', newNotif);
            attachMarkReadHandlers();
            const audio = document.getElementById("notificationSound");
            if (audio) {
                audio.muted = false;
                audio.volume = 0.6;
                audio.play().catch(() => {});
            }
        }

        const audio = document.getElementById('notif-sound');
        if (audio) {
            audio.volume = 0.6;
            audio.play().catch(() => {});
        }

        NotificationBus.emit('notifications:new', { notification: e });
    });

    function fetchNotificationsCount() {
        if (!api) return;
        fetch(api.countUrl)
            .then(res => res.json())
            .then(data => {
                if (notifCountEl) {
                    if (data.count > 0) {
                        notifCountEl.style.display = 'inline';
                        notifCountEl.textContent = data.count;
                    } else {
                        notifCountEl.style.display = 'none';
                    }
                }
                NotificationBus.emit('notifications:count', { count: data.count });
            })
            .catch(() => { if (notifCountEl) notifCountEl.style.display = 'none'; });
    }

    window.openModal = function (e) {
        if (e) e.preventDefault();
        if (!modal) return;

        modal.classList.add('active');
        document.body.style.overflow = 'hidden';

        if (notifContentEl && api) {
            notifContentEl.innerHTML = `<div class="text-center text-muted p-3">جاري تحميل الإشعارات...</div>`;
            fetch(api.listUrl)
                .then(res => res.text())
                .then(html => {
                    notifContentEl.innerHTML = html;
                    attachMarkReadHandlers();
                })
                .catch(() => notifContentEl.innerHTML = `<div class="text-center text-danger p-3">فشل تحميل الإشعارات.</div>`);
        }
    };

    function closeModal() {
        if (!modal) return;
        modal.classList.remove('active');
        document.body.style.overflow = '';
    }

    if (closeBtn) closeBtn.addEventListener('click', closeModal);
    if (modal) modal.addEventListener('click', e => { if (e.target === modal) closeModal(); });

    window.markAsRead = function (id) {
        return fetch(`/admin/notifications/mark-as-read/${id}`, {
            method: 'POST',
            headers: { 'X-CSRF-TOKEN': csrfToken, 'Accept': 'application/json' }
        }).then(res => res.json());
    };

    function attachMarkReadHandlers() {
        notifContentEl.querySelectorAll('.mark-read-btn').forEach(btn => {
            btn.removeEventListener('click', onMarkClick);
            btn.addEventListener('click', onMarkClick);
        });
    }

    function onMarkClick() {
        const id = this.dataset.id;
        if (!id) return;

        markAsRead(id)
            .then(() => {
                const item = this.closest('.notification-item');
                if (item) item.classList.remove('unread');
                const current = parseInt(notifCountEl.textContent || '0', 10);
                const next = Math.max(0, current - 1);
                if (next > 0) notifCountEl.textContent = next;
                else notifCountEl.style.display = 'none';
                NotificationBus.emit('notifications:count', { count: next });
            })
            .catch(() => alert('حدث خطأ أثناء تمييز الإشعار كمقروء'));
    }

    // تمييز الكل كمقروء
    if (markAllBtn && api) {
        markAllBtn.addEventListener('click', function () {
            fetch(api.markReadUrl, { method: 'POST', headers: { 'X-CSRF-TOKEN': csrfToken, 'Accept': 'application/json' } })
                .then(() => {
                    notifContentEl.querySelectorAll('.notification-item.unread').forEach(el => el.classList.remove('unread'));
                    notifCountEl.style.display = 'none';
                    NotificationBus.emit('notifications:count', { count: 0 });
                })
                .catch(() => alert('فشل تمييز الكل كمقروء'));
        });
    }

    fetchNotificationsCount();
    handleNotificationClick();
    // setInterval(fetchNotificationsCount, 60000);

    document.addEventListener("click", function enableSound() {
        const audio = document.getElementById("notificationSound");
        if (audio) {
            audio.muted = false;
            audio.volume = 0.0;
            audio.play().catch(() => {});
        }
        document.removeEventListener("click", enableSound);
    });

    function handleNotificationClick(id, url) {
        if (!id) return;

        fetch(`/admin/notifications/mark-as-read/${id}`, {
            method: 'POST',
            headers: {
                'X-CSRF-TOKEN': csrfToken,
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            credentials: 'same-origin', 
        })
        .then(res => res.json())
        .then(data => {
            const el = document.querySelector(`.notification-item[data-id='${id}']`);
            if (el) {
                el.classList.remove('unread');
                el.classList.add('read');
            }

            if (url) {
                window.location.href = url; 
            }
        })
        .catch(err => console.error('Error marking notification:', err));
    }
});
