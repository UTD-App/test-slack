<?php

return [

    // ── Core notification type texts (templated; :placeholders filled from params) ──
    'welcome'      => 'Welcome to :app!',
    'announcement' => ':body', // fallback only; admin announcements carry a per-locale body map

    // ── API response messages ──
    'marked_read'         => 'Notification marked as read.',
    'marked_all_read'     => 'All notifications marked as read.',
    'preferences_updated' => 'Notification preferences updated.',
    'device_registered'   => 'Device registered for notifications.',

];
