<?php

namespace App\Actions\AdminRequests;

use App\Actions\Batches\UnenrollStudent;
use App\Actions\Mentoring\UnassignMasterTeacher;
use App\Enums\AdminRequestType;
use App\Exceptions\ApiException;
use App\Models\AdminRequest;
use App\Support\ErrorCode;

class ApplyAdminRequestAction
{
    public function __construct(
        private readonly UnassignMasterTeacher $unassignMasterTeacher,
        private readonly UnenrollStudent $unenrollStudent,
    ) {}

    public function execute(AdminRequest $adminRequest): void
    {
        match ($adminRequest->request_type) {
            AdminRequestType::RemoveMentee => $this->applyRemoveMentee($adminRequest),
            AdminRequestType::RemoveBatchStudent => $this->applyRemoveBatchStudent($adminRequest),
            AdminRequestType::General => null,
        };
    }

    private function applyRemoveMentee(AdminRequest $adminRequest): void
    {
        $student = $adminRequest->student;
        if ($student === null) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Student for this request was not found.', 404);
        }

        $this->unassignMasterTeacher->execute($student);
    }

    private function applyRemoveBatchStudent(AdminRequest $adminRequest): void
    {
        $student = $adminRequest->student;
        $batch = $adminRequest->batch;

        if ($student === null || $batch === null) {
            throw new ApiException(ErrorCode::NOT_FOUND, 'Student or batch for this request was not found.', 404);
        }

        $this->unenrollStudent->execute($batch, $student);
    }
}
