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

    // ── App UI strings (the Flutter notifications.* keys) ──
    'title'         => 'Notifications',
    'empty'         => 'No notifications yet',
    'empty_hint'    => "When something happens, you'll see it here.",
    'mark_all_read' => 'Mark all read',
    'error'         => 'Could not load notifications',
    'retry'         => 'Retry',

];
