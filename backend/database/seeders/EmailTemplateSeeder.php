<?php

namespace Database\Seeders;

use App\Models\EmailTemplate;
use Illuminate\Database\Seeder;

/**
 * Ensures a DB row exists for every registered email-template type, pre-filled
 * with its default subject/body (en, ar). firstOrCreate → re-seeding never
 * overwrites an admin's edits. New types (from packages) get picked up on the
 * next seed, or on the first visit to the admin Email Templates page.
 */
class EmailTemplateSeeder extends Seeder
{
    public function run(): void
    {
        EmailTemplate::ensureRegisteredRows();
    }
}
