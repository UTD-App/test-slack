<?php

namespace App\Contracts;

use App\Models\User;

interface UserDataContributor
{
    public function getKey(): string;

    public function getUserData(User $user): ?array;
}
