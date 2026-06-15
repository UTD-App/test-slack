<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition(): array
    {
        return [
            'name'              => fake()->name(),
            'email'             => fake()->unique()->safeEmail(),
            'phone'             => fake()->unique()->numerify('+2010########'),
            'uuid'              => (string) Str::uuid(),
            'email_verified_at' => now(),
            'password'          => 'password',
            'status'            => true,
        ];
    }

    /** A soft-disabled user. */
    public function inactive(): static
    {
        return $this->state(fn () => ['status' => false]);
    }
}
