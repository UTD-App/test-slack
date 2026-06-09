<?php

// Base project API messages only.
// Package-specific messages (gifts, audio-room, agency, etc.)
// must be registered by their packages via POST /api/packages/register

return [
    'welcome'         => 'Welcome to :name',
    'success'         => 'Operation completed successfully.',
    'error'           => 'An error occurred. Please try again.',
    'unauthorized'    => 'Unauthorized access.',
    'not_found'       => 'Resource not found.',
    'validation'      => 'The given data was invalid.',
    'ban_user'        => 'Your account is banned. Contact support.',
    'remove_ban'      => 'Your account ban has been lifted.',
    'followed_you'    => ':name followed you',
    'visited_profile' => ':name visited your profile',
    'message'         => ':name sent you a message',
    'app_message'     => 'You have a new message from :appName',
    'kick_out'        => 'You have been removed from the room',
];
