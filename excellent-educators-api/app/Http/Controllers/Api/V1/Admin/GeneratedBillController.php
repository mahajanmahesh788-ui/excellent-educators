<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreGeneratedBillRequest;
use App\Http\Requests\Api\V1\Admin\UpdateGeneratedBillRequest;
use App\Http\Resources\Api\V1\GeneratedBillResource;
use App\Models\GeneratedBill;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GeneratedBillController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = GeneratedBill::query()->orderByDesc('created_at');

        if ($search = trim((string) $request->query('q', ''))) {
            $query->where(function ($builder) use ($search): void {
                $builder
                    ->where('full_name', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('bill_number', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $bills = $query->limit(200)->get();

        return ApiResponse::success(
            'Generated bills fetched successfully.',
            GeneratedBillResource::collection($bills)->resolve(),
        );
    }

    public function store(StoreGeneratedBillRequest $request): JsonResponse
    {
        $data = $this->normalizedPayload($request->validated(), creating: true);
        $bill = DB::transaction(function () use ($data, $request) {
            return GeneratedBill::query()->create([
                ...$data,
                'bill_number' => $this->nextBillNumber(),
                'created_by' => $request->user()?->id,
            ]);
        });

        return ApiResponse::success(
            'Bill generated successfully.',
            (new GeneratedBillResource($bill))->resolve(),
            status: 201,
        );
    }

    public function show(GeneratedBill $generatedBill): JsonResponse
    {
        return ApiResponse::success(
            'Generated bill fetched successfully.',
            (new GeneratedBillResource($generatedBill))->resolve(),
        );
    }

    public function update(
        UpdateGeneratedBillRequest $request,
        GeneratedBill $generatedBill,
    ): JsonResponse {
        $generatedBill->update(
            $this->normalizedPayload($request->validated(), creating: false),
        );

        return ApiResponse::success(
            'Bill updated successfully.',
            (new GeneratedBillResource($generatedBill->fresh() ?? $generatedBill))->resolve(),
        );
    }

    public function destroy(GeneratedBill $generatedBill): JsonResponse
    {
        $generatedBill->delete();

        return ApiResponse::success('Bill deleted successfully.');
    }

    /**
     * @param  array<string, mixed>  $input
     * @return array<string, mixed>
     */
    private function normalizedPayload(array $input, bool $creating): array
    {
        $data = [];
        foreach ([
            'full_name',
            'email',
            'phone',
            'whatsapp_number',
            'address',
            'class_grade',
            'gender',
            'guardian_name',
            'guardian_phone',
            'payment_type',
            'notes',
        ] as $key) {
            if (array_key_exists($key, $input)) {
                $data[$key] = $input[$key];
            }
        }

        if (array_key_exists('payment_mode', $input) || $creating) {
            $data['payment_mode'] = ($input['payment_mode'] ?? null) ?: 'offline';
        }

        if (array_key_exists('bill_date', $input) || $creating) {
            $data['bill_date'] = ($input['bill_date'] ?? null) ?: now()->toDateString();
        }

        $paymentType = (string) ($data['payment_type'] ?? $input['payment_type'] ?? 'full');

        if (array_key_exists('total_amount', $input)) {
            $total = (float) $input['total_amount'];
            $data['total_amount'] = $total;
            $paid = array_key_exists('paid_amount', $input)
                ? (float) $input['paid_amount']
                : ($paymentType === 'full' ? $total : 0.0);
            $data['paid_amount'] = max(0, min($paid, $total));
        } elseif (array_key_exists('paid_amount', $input)) {
            $data['paid_amount'] = max(0, (float) $input['paid_amount']);
        }

        return $data;
    }

    private function nextBillNumber(): string
    {
        $prefix = 'BILL-'.now()->format('Ym').'-';

        $latest = GeneratedBill::query()
            ->where('bill_number', 'like', $prefix.'%')
            ->orderByDesc('bill_number')
            ->value('bill_number');

        $sequence = 1;
        if (is_string($latest) && preg_match('/(\d+)$/', $latest, $matches) === 1) {
            $sequence = ((int) $matches[1]) + 1;
        }

        return $prefix.str_pad((string) $sequence, 4, '0', STR_PAD_LEFT);
    }
}
