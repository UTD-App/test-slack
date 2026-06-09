<?php

namespace Utd\Moment\Http\Services;

use App\Models\User;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentCommint;

class MomentCommentsService
{
    public function add($data, Moment $moment, User $user)
    {
        $moment->comments()->create([
            'user_id' => $user->id,
            'comment' => $data['comment'],
        ]);

        return true;
    }

    public function delete($comment_id, Moment $moment)
    {
        $commint = MomentCommint::find($comment_id);
        if (! $commint) {
            return 'false';
        }

        $moment->comments()->where('moment_user_comments.id', $comment_id)->delete();
    }

    public function showComments($moment)
    {
        return $moment->comments()
            ->has('user')
            ->with([
                'user' => function ($query) {
                    $query->select(['id', 'uuid', 'name', 'avatar'])->with('profile:id,user_id,avatar');
                },
            ])->orderByDesc('id')->paginate(10);
    }
}
