import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';
import 'package:excellent_educators_web/features/payments/data/payment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(apiClientProvider));
});

class PaymentListFilter {
  const PaymentListFilter({
    this.status,
    this.period,
    this.paymentType,
    this.preferredMode,
    this.search,
    this.page = 1,
  });

  final String? status;
  final String? period;
  final String? paymentType;
  final String? preferredMode;
  final String? search;
  final int page;

  PaymentListFilter copyWith({
    String? status,
    String? period,
    String? paymentType,
    String? preferredMode,
    String? search,
    int? page,
    bool clearStatus = false,
    bool clearPeriod = false,
  }) {
    return PaymentListFilter(
      status: clearStatus ? null : (status ?? this.status),
      period: clearPeriod ? null : (period ?? this.period),
      paymentType: paymentType ?? this.paymentType,
      preferredMode: preferredMode ?? this.preferredMode,
      search: search ?? this.search,
      page: page ?? this.page,
    );
  }
}

final paymentListFilterProvider =
    StateProvider.autoDispose<PaymentListFilter>((ref) {
  return const PaymentListFilter(status: 'pending_balance');
});

final paymentListProvider =
    FutureProvider.autoDispose<PaymentListResult>((ref) {
  final filter = ref.watch(paymentListFilterProvider);
  return ref.watch(paymentRepositoryProvider).listPlans(
        status: filter.status,
        period: filter.period,
        paymentType: filter.paymentType,
        preferredMode: filter.preferredMode,
        search: filter.search,
        page: filter.page,
      );
});

final adminStudentPaymentPlanProvider =
    FutureProvider.autoDispose.family<StudentPaymentPlanDto?, String>((
  ref,
  studentId,
) {
  return ref.watch(paymentRepositoryProvider).studentPlan(studentId);
});

final studentOwnPaymentsProvider =
    FutureProvider.autoDispose<StudentSelfPaymentDto>((ref) {
  return ref.watch(paymentRepositoryProvider).ownPayments();
});
