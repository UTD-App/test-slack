<?php

namespace Utd\Reels\Http\Services;

use Illuminate\Database\Eloquent\Model;

abstract class ReelsBaseModelService
{
    public $model;

    public function __construct(Model $model)
    {
        $this->model = $model;
    }

    public function findOrFail($id)
    {
        return $this->model->findOrFail($id);
    }
}
