<?php

// Base project global helpers
// Feature-specific helpers (Agora, etc.) are added by their respective packages/modules

if (!function_exists('numToStringNew')) {
    /**
     * Format a number for compact display (used on the landing page stats).
     *
     * Examples: 950 => "950", 1500 => "1.5K", 2000000 => "2M".
     */
    function numToStringNew($number): string
    {
        $number = (int) $number;

        if ($number < 1000) {
            return (string) $number;
        }

        $units = ['', 'K', 'M', 'B', 'T'];
        $power = (int) floor(log($number, 1000));
        $power = min($power, count($units) - 1);

        $value = $number / pow(1000, $power);
        // One decimal, but drop a trailing ".0" (e.g. 2.0K -> 2K).
        $formatted = rtrim(rtrim(number_format($value, 1), '0'), '.');

        return $formatted . $units[$power];
    }
}
