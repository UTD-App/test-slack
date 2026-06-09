<?php

namespace Utd\Moment\Http\Services;

use App\Models\User;
use Utd\Moment\Entities\Moment;

class MomentLikesService extends MomentBaseModelService
{
    public function __construct(Moment $model)
    {
        parent::__construct($model);
    }

    public function add(Moment $moment, User $user)
    {
        $moment->likes()->create(['user_id' => $user->id]);

        return true;
    }

    public function likeOrUnLike(Moment $moment, User $user)
    {
        $likeData = $moment->likes()->where('user_id', $user->id)->first();

        if ($likeData) {
            $likeData->delete();

            return 'un Like';
        }

        $moment->likes()->create(['user_id' => $user->id]);

        return 'Like';
    }

    public function delete($like_id, Moment $moment)
    {
        $moment->likes()->where('id', $like_id)->delete();
    }

    public function showLikes($moment)
    {
        return $moment->likes()->with([
            'user' => function ($query) {
                $query->select(['id', 'name', 'uuid', 'avatar'])->with('profile:id,user_id,avatar');
            },
        ])->orderByDesc('id')->paginate(10);
    }
}
