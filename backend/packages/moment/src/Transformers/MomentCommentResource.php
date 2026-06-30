<?php

namespace Utd\Moment\Transformers;

use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Auth;

class MomentCommentResource extends JsonResource
{
    public function toArray($request)
    {
        // Reaction summary (computed from the eager-loaded `likes` relation so the
        // comments list stays a single query). like_num = total, my_reaction = the
        // current user's reaction or null, reactions = per-type breakdown.
        $likeNum = 0;
        $myReaction = null;
        $reactions = (object) [];

        if ($this->resource->relationLoaded('likes')) {
            $likes = $this->likes;
            $likeNum = $likes->count();

            $uid = Auth::id();
            if ($uid) {
                $myReaction = optional($likes->firstWhere('user_id', $uid))->reaction_type;
            }

            $grouped = $likes->groupBy('reaction_type')->map->count();
            if ($grouped->isNotEmpty()) {
                $reactions = $grouped;
            }
        }

        return [
            'id'          => $this->id,
            'moment_id'   => $this->moment_id,
            'parent_id'   => $this->parent_id,
            'user_id'     => $this->user_id,
            'comment'     => $this->comment,
            'created_at'  => $this->created_at,
            'updated_at'  => $this->updated_at,
            'like_num'    => $likeNum,
            'my_reaction' => $myReaction,
            'reactions'   => $reactions,
            'user'        => $this->whenLoaded('user') ? new UserResource($this->whenLoaded('user')) : null,
            'replies'     => MomentCommentResource::collection($this->whenLoaded('replies')),
        ];
    }
}
