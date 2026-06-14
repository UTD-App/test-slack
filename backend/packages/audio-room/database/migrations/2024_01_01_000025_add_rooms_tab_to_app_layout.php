<?php

use App\Models\StacScreen;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        $screen = StacScreen::where('name', 'app_layout')->first();
        if (!$screen) {
            return;
        }

        $content = $screen->content;
        $tabs = $content['bottomNav']['tabs'] ?? [];

        foreach ($tabs as $tab) {
            if (($tab['featureId'] ?? '') === 'com.utd.audio_room') {
                return;
            }
        }

        $roomTab = [
            'icon'      => 'mic',
            'kind'      => 'native',
            'label'     => 'الغرف',
            'route'     => '/rooms',
            'screen'    => 'rooms',
            'featureId' => 'com.utd.audio_room',
        ];

        array_splice($tabs, 1, 0, [$roomTab]);
        $content['bottomNav']['tabs'] = $tabs;

        $screen->update([
            'content' => $content,
            'version' => substr(md5(json_encode($content)), 0, 12),
        ]);
    }

    public function down(): void
    {
        $screen = StacScreen::where('name', 'app_layout')->first();
        if (!$screen) {
            return;
        }

        $content = $screen->content;
        $tabs = $content['bottomNav']['tabs'] ?? [];

        $content['bottomNav']['tabs'] = array_values(
            array_filter($tabs, fn($t) => ($t['featureId'] ?? '') !== 'com.utd.audio_room')
        );

        $screen->update([
            'content' => $content,
            'version' => substr(md5(json_encode($content)), 0, 12),
        ]);
    }
};
