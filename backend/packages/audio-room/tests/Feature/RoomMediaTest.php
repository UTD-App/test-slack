<?php

namespace Utd\AudioRoom\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\AudioRoom\Entities\Room;
use Utd\AudioRoom\Entities\RoomVisitor;

/**
 * A9 — the room payload must return visitor avatars (and the owner avatar) as
 * ABSOLUTE URLs. Raw stored paths (avatars/x.jpg) would 404 on the client.
 */
class RoomMediaTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        return [$user, $token];
    }

    public function test_visitor_images_are_resolved_to_absolute_urls(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = Room::create([
            'num_id'    => 100001,
            'user_id'   => $owner->id,
            'room_name' => 'QA Room',
        ]);

        $visitor = User::factory()->create();
        $visitor->profile()->updateOrCreate(['user_id' => $visitor->id], ['avatar' => 'avatars/visitor.jpg']);
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $visitor->id]);

        $images = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/rooms/{$room->id}")
            ->assertStatus(200)
            ->json('data.visitor_images');

        $this->assertCount(1, $images);
        $this->assertNotSame('avatars/visitor.jpg', $images[0], 'visitor avatar must not be a raw path');
        $this->assertStringStartsWith('http', $images[0]);
        $this->assertStringContainsString('avatars/visitor.jpg', $images[0]);
    }

    public function test_visitor_image_passes_through_absolute_url(): void
    {
        [$owner, $token] = $this->actingUser();
        $room = Room::create([
            'num_id'    => 100002,
            'user_id'   => $owner->id,
            'room_name' => 'QA Room 2',
        ]);

        $visitor = User::factory()->create();
        $visitor->profile()->updateOrCreate(
            ['user_id' => $visitor->id],
            ['avatar' => 'https://cdn.example.com/v.jpg'],
        );
        RoomVisitor::create(['room_id' => $room->id, 'user_id' => $visitor->id]);

        $images = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/rooms/{$room->id}")
            ->assertStatus(200)
            ->json('data.visitor_images');

        $this->assertSame(['https://cdn.example.com/v.jpg'], $images);
    }
}
