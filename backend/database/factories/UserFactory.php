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
        $name = fake()->name();

        return [
            'name' => $name,
            'email' => fake()->unique()->safeEmail(),
            'phone' => fake()->unique()->numerify('+20100#######'),
            'uuid' => (string) Str::uuid(),
            'password' => 'password',
            'avatar' => "https://i.pravatar.cc/300?u=" . Str::slug($name) . fake()->numberBetween(1, 9999),
            'img' => "https://i.pravatar.cc/300?u=" . Str::slug($name) . fake()->numberBetween(1, 9999),
            'bio' => fake()->sentence(),
            'gender' => fake()->numberBetween(1, 2),
            'status' => true,
            'online' => fake()->boolean(40),
        ];
    }
}
