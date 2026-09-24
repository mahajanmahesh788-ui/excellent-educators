<?php

namespace App\Enums;

enum TeacherLeaveStatus: string
{
    case Pending = 'pending';
    case ReassignmentPending = 'reassignment_pending';
    case Approved = 'approved';
    case Rejected = 'rejected';
    case Cancelled = 'cancelled';

    /**
     * @return list<string>
     */
    public static function activeValues(): array
    {
        return [
            self::Pending->value,
            self::ReassignmentPending->value,
            self::Approved->value,
        ];
    }

    /**
     * @return list<string>
     */
    public static function bookingHoldValues(): array
    {
        return [
            self::Pending->value,
            self::ReassignmentPending->value,
            self::Approved->value,
        ];
    }

    /**
     * @return list<string>
     */
    public static function openValues(): array
    {
        return [
            self::Pending->value,
            self::ReassignmentPending->value,
        ];
    }

    public function isOpen(): bool
    {
        return in_array($this, [self::Pending, self::ReassignmentPending], true);
    }
}
