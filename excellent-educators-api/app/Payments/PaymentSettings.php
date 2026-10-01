<?php

namespace App\Payments;

use App\Support\AppSettings;

class PaymentSettings
{
    public const FULL_AMOUNT = 'payment_full_amount';
    public const PARTIAL_TOTAL = 'payment_partial_total';

    private const DEFAULT_DUE_DAY = 20;
    private const DEFAULT_GRACE_DAYS = 0;

    public function __construct(private readonly AppSettings $settings) {}

    /**
     * @return list<array<string, mixed>>
     */
    public static function catalogItems(): array
    {
        return [
            [
                'key' => self::FULL_AMOUNT,
                'group' => 'payments',
                'group_label' => 'Payment Settings',
                'label' => 'Full payment amount (₹)',
                'help' => 'Default for NEW students only. Existing students keep the amount locked on their payment plan.',
                'type' => 'integer',
                'min' => 0,
                'max' => 10000000,
                'default' => 6000,
            ],
            [
                'key' => self::PARTIAL_TOTAL,
                'group' => 'payments',
                'group_label' => 'Payment Settings',
                'label' => 'Partial payment total amount (₹)',
                'help' => 'Default for NEW students only. Existing students keep the amount locked on their payment plan.',
                'type' => 'integer',
                'min' => 0,
                'max' => 10000000,
                'default' => 6500,
            ],
        ];
    }

    public function fullAmount(): float
    {
        return (float) $this->settings->get(self::FULL_AMOUNT);
    }

    public function partialTotal(): float
    {
        return (float) $this->settings->get(self::PARTIAL_TOTAL);
    }

    public function dueDay(): int
    {
        return self::DEFAULT_DUE_DAY;
    }

    public function graceDays(): int
    {
        return self::DEFAULT_GRACE_DAYS;
    }

    public function partialEnabled(): bool
    {
        return true;
    }

    public function onlineEnabled(): bool
    {
        // Manual UPI scan-and-pay (QR). Students confirm after paying; no card gateway yet.
        return true;
    }

    public function offlineEnabled(): bool
    {
        return true;
    }
}
