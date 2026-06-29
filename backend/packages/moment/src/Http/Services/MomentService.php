<?php

namespace Utd\Moment\Http\Services;

use App\Contracts\MediaUploader;
use Illuminate\Support\Facades\Auth;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentGallery;
use Utd\Moment\Http\Repositories\MomentRepository;

class MomentService extends MomentBaseModelService
{
    public function __construct(Moment $model, public MomentRepository $momentRepository)
    {
        parent::__construct($model);
    }

    public function getMomentsByType($type, $userId, $page, $currentUser)
    {
        switch ((int) $type) {
            case 1:
                return $this->momentRepository->getUserMoments($userId ?? $currentUser, $page);
            case 2:
                return $this->momentRepository->getLikedMoments($currentUser, $page);
            case 3:
                return $this->momentRepository->getFollowedMoments($currentUser, $page);
            case 4:
                return $this->momentRepository->getAllMoments($currentUser, $page);
            case 5:
                return $this->momentRepository->getNewMoments($currentUser);
            case 6:
                return $this->momentRepository->momentUserFollow($currentUser);
            default:
                return null;
        }
    }

    public function deleteMomentAndReport($momentId, $reportId)
    {
        $moment = $this->momentRepository->findMomentById($momentId);
        if (! $moment) {
            return ['success' => false, 'message' => __('moment::messages.not_found'), 'status' => 404];
        }

        $reportMoment = $this->momentRepository->findReportMomentById($reportId);
        if ($reportMoment) {
            $this->momentRepository->deleteReportMoment($reportMoment);
        }

        $this->momentRepository->deleteMoment($moment);

        return ['success' => true, 'message' => __('moment::messages.report_deleted'), 'status' => 200];
    }

    public function deleteMomentById($id, $userId = null)
    {
        $moment = $this->momentRepository->findMomentById($id);
        if (! $moment) {
            return ['success' => false, 'message' => __('moment::messages.not_found'), 'status' => 404];
        }

        // Ownership guard: only the author may delete via the API.
        // (Admins remove moments through the Filament MomentResource, not here.)
        if ($userId !== null && (int) $moment->user_id !== (int) $userId) {
            return ['success' => false, 'message' => __('moment::messages.not_owner'), 'status' => 403];
        }

        $this->momentRepository->deleteMoment($moment);

        return ['success' => true, 'message' => __('moment::messages.deleted'), 'status' => 200];
    }

    public function createMoment($contacts, $request)
    {
        $userId = Auth::id();

        $hasImages = $request->hasFile('multi_image');

        if (empty($contacts) && ! $hasImages) {
            return ['success' => false, 'message' => __('moment::messages.empty_content')];
        }

        $moment = $this->momentRepository->createMoment([
            'user_id'     => $userId,
            'description' => $contacts,
        ]);

        if (! $moment) {
            return ['success' => false, 'message' => __('moment::messages.try_again')];
        }

        // Image upload via the Base MediaUploader contract (no FFMpeg/Job dependency).
        if ($hasImages) {
            $uploader = app(MediaUploader::class);
            foreach ($request->file('multi_image') as $file) {
                if ($file && $file->isValid()) {
                    $result = $uploader->upload($file, 'moments');
                    MomentGallery::create([
                        'moment_id' => $moment->id,
                        'image'     => $result->path,
                    ]);
                }
            }
        }

        return ['success' => true, 'message' => __('moment::messages.success')];
    }

    public function getMoment($id, $userId)
    {
        $moment = $this->momentRepository->getMomentById($id, $userId);

        if (! $moment) {
            return ['success' => false, 'message' => __('moment::messages.not_found'), 'data' => null, 'status' => 404];
        }

        return ['success' => true, 'message' => '', 'data' => $moment, 'status' => 200];
    }

    public function delete(int|Moment $moment)
    {
        if (is_int($moment)) {
            $moment = Moment::query()->find($moment);
        }

        $moment?->delete();
    }
}
