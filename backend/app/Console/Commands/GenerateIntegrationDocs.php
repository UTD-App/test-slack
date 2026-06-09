<?php

namespace App\Console\Commands;

use App\Models\StacScreen;
use App\Support\UtdManifest;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Route;

/**
 * Generates the UTD ⇄ Base integration documentation FROM the live system
 * (routes + registered manifest + pushed screens) instead of hand-writing it.
 *
 *   php artisan utd:integration-docs
 *
 * Output: <repo>/docs/INTEGRATION.generated.md
 */
class GenerateIntegrationDocs extends Command
{
    protected $signature = 'utd:integration-docs {--out= : Custom output path}';

    protected $description = 'Generate integration docs from routes, manifest and pushed Stac screens';

    /** Stac widget types this base can render (built-ins + UTD custom parsers). */
    private const SUPPORTED_TYPES = [
        'app', 'scaffold', 'appBar', 'bottomNavigationBar', 'bottomNavigationBarItem',
        'column', 'row', 'stack', 'container', 'gridView', 'singleChildScrollView',
        'text', 'icon', 'image', 'elevatedButton', 'textButton', 'divider',
        'floatingActionButton', 'gestureDetector', 'expanded', 'sizedBox', 'padding',
        // نماذج ستايل/قيم متداخلة (مش widgets لكنها أنواع Stac صحيحة):
        'textStyle', 'edgeInsets', 'boxDecoration', 'gradient', 'linearGradient',
        'border', 'borderRadius', 'boxShadow',
        // UTD custom parsers (see flutter/lib/shared/stac):
        'utdList',
    ];

    public function handle(): int
    {
        $out = $this->option('out') ?: base_path('../docs/INTEGRATION.generated.md');
        @mkdir(dirname($out), 0775, true);

        $md = $this->render();

        file_put_contents($out, $md);
        $this->info("Integration docs written to: {$out}");

        return self::SUCCESS;
    }

    private function render(): string
    {
        $lines = [];
        $lines[] = '# UTD ⇄ Base Project — Integration (Generated)';
        $lines[] = '';
        $lines[] = '> **مولَّد تلقائياً** بـ `php artisan utd:integration-docs` من الـ routes + manifest + الشاشات المدفوعة.';
        $lines[] = '> لا تُعدّله يدوياً — أعِد توليده.';
        $lines[] = '';

        // 1. Integration routes
        $lines[] = '## 1. قنوات التكامل (Routes الفعلية)';
        $lines[] = '';
        $lines[] = '| Method | URI | Auth/Middleware |';
        $lines[] = '|---|---|---|';
        foreach (Route::getRoutes() as $route) {
            $uri = $route->uri();
            if (! str_contains($uri, 'utd') && ! str_contains($uri, 'stac')) {
                continue;
            }
            $methods = implode('|', array_diff($route->methods(), ['HEAD']));
            $mw = implode(', ', $route->gatherMiddleware()) ?: '—';
            $lines[] = "| {$methods} | `{$uri}` | {$mw} |";
        }
        $lines[] = '';

        // 2. Manifest (registered packages + elements)
        $lines[] = '## 2. Manifest — الـ packages وعناصرها (مسجّلة فعلياً)';
        $lines[] = '';
        $packages = UtdManifest::all();
        if (empty($packages)) {
            $lines[] = '_لا توجد packages مسجّلة (تأكد أن ServiceProviders بتاعتها محمّلة)._';
        }
        foreach ($packages as $pkg) {
            $lines[] = "### 📦 {$pkg['name']} (`{$pkg['key']}`)";
            $lines[] = '';
            $lines[] = '- Screens: ' . implode(', ', $pkg['screens'] ?: ['—']);
            $lines[] = '';
            $lines[] = '| Element | Type | Screen |';
            $lines[] = '|---|---|---|';
            foreach (($pkg['elements'] ?? []) as $el) {
                $lines[] = "| `{$el['key']}` | {$el['type']} | {$el['screen']} |";
            }
            if (! empty($pkg['action_elements'])) {
                $lines[] = '';
                $lines[] = '**Action elements:** ' .
                    implode(', ', array_map(fn ($a) => "`{$a['key']}` ({$a['produces']})", $pkg['action_elements']));
            }
            $lines[] = '';
        }

        // 3. Pushed screens + rendering compatibility
        $lines[] = '## 3. الشاشات المدفوعة + توافق الـ Rendering';
        $lines[] = '';
        $screens = StacScreen::query()->get(['name', 'package', 'version', 'content', 'is_active']);
        if ($screens->isEmpty()) {
            $lines[] = '_لا توجد شاشات مدفوعة بعد._';
        } else {
            $lines[] = '| Screen | Package | Version | Active | أنواع غير مدعومة |';
            $lines[] = '|---|---|---|---|---|';
            foreach ($screens as $screen) {
                $types = $this->collectTypes($screen->content);
                $unsupported = array_values(array_diff($types, self::SUPPORTED_TYPES));
                $warn = empty($unsupported) ? '✅ —' : '⚠️ ' . implode(', ', $unsupported);
                $active = $screen->is_active ? '✓' : '—';
                $lines[] = "| `{$screen->name}` | {$screen->package} | {$screen->version} | {$active} | {$warn} |";
            }
        }
        $lines[] = '';
        $lines[] = '> ⚠️ نوع غير مدعوم = الـ Flutter لن يرسمه. أضِف parser مخصص أو عدّل التصميم.';
        $lines[] = '';

        return implode("\n", $lines);
    }

    /** Recursively collect every `type` value found in a screen content tree. */
    private function collectTypes(mixed $node, array &$acc = []): array
    {
        if (is_array($node)) {
            if (isset($node['type']) && is_string($node['type'])) {
                $acc[$node['type']] = true;
            }
            foreach ($node as $value) {
                $this->collectTypes($value, $acc);
            }
        }

        return array_keys($acc);
    }
}
