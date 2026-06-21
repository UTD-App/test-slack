<?php

namespace Database\Seeders;

use App\Models\Page;
use Illuminate\Database\Seeder;

class PagesSeeder extends Seeder
{
    public function run(): void
    {
        $pages = [
            [
                'key'   => 'privacy-policy',
                'title' => ['en' => 'Privacy Policy', 'ar' => 'سياسة الخصوصية'],
                'body'  => [
                    'en' => "Your privacy matters to us.\n\nThis is placeholder content. Replace it from Admin → Pages → Privacy Policy.",
                    'ar' => "خصوصيتك تهمنا.\n\nهذا نص مبدئي. عدّله من لوحة التحكم ← الصفحات ← سياسة الخصوصية.",
                ],
            ],
            [
                'key'   => 'terms',
                'title' => ['en' => 'Terms of Service', 'ar' => 'شروط الخدمة'],
                'body'  => [
                    'en' => "These are the terms of service.\n\nThis is placeholder content. Replace it from Admin → Pages → Terms of Service.",
                    'ar' => "هذه هي شروط الخدمة.\n\nهذا نص مبدئي. عدّله من لوحة التحكم ← الصفحات ← شروط الخدمة.",
                ],
            ],
            [
                'key'   => 'about-us',
                'title' => ['en' => 'About Us', 'ar' => 'من نحن'],
                'body'  => [
                    'en' => "Welcome to our app.\n\nThis is placeholder content. Replace it from Admin → Pages → About Us.",
                    'ar' => "مرحبًا بك في تطبيقنا.\n\nهذا نص مبدئي. عدّله من لوحة التحكم ← الصفحات ← من نحن.",
                ],
            ],
        ];

        foreach ($pages as $p) {
            // firstOrCreate so re-seeding never clobbers admin-edited content.
            Page::firstOrCreate(['key' => $p['key']], ['title' => $p['title'], 'body' => $p['body']]);
        }
    }
}
