import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/maps_api_failures.dart';
import 'package:excellent_educators_web/features/payments/data/dto/payment_dtos.dart';

class PaymentRepository with MapsApiFailures {
  PaymentRepository(this._client);

  final ApiClient _client;

  Future<PaymentOverviewDto> overview() {
    return runApiSimple(() async {
      final json = await _client.get(ApiEndpoints.adminPaymentsOverview);
      return PaymentOverviewDto.fromJson(json ?? const {});
    });
  }

  Future<PaymentListResult> listPlans({
    String? status,
    String? period,
    String? from,
    String? to,
    String? paymentType,
    String? preferredMode,
    String? levelId,
    String? batchId,
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return runApiSimple(() async {
      final envelope = await _client.getRaw(
        ApiEndpoints.adminPayments,
        query: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (period != null && period.isNotEmpty) 'period': period,
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
          if (paymentType != null && paymentType.isNotEmpty)
            'payment_type': paymentType,
          if (preferredMode != null && preferredMode.isNotEmpty)
            'preferred_mode': preferredMode,
          if (levelId != null && levelId.isNotEmpty) 'level_id': levelId,
          if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'per_page': perPage,
        },
      );
      final data = envelope.data is Map
          ? Map<String, dynamic>.from(envelope.data as Map)
          : const <String, dynamic>{};
      final items = (data['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => StudentPaymentPlanDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
      final summary = data['summary'] is Map
          ? PaymentOverviewDto.fromJson(
              Map<String, dynamic>.from(data['summary'] as Map),
            )
          : const PaymentOverviewDto(
              allPending: 0,
              dueThisMonth: 0,
              overdue: 0,
              paidThisMonth: 0,
            );
      return PaymentListResult(
        items: items,
        summary: summary,
        meta: envelope.meta,
      );
    });
  }

  Future<StudentPaymentPlanDto?> studentPlan(String studentId) {
    return runApiSimple(() async {
      final json = await _client.get(ApiEndpoints.adminStudentPayments(studentId));
      final plan = json?['plan'];
      if (plan is! Map) {
        return null;
      }
      return StudentPaymentPlanDto.fromJson(Map<String, dynamic>.from(plan));
    });
  }

  Future<StudentPaymentPlanDto> savePlan(
    String studentId,
    Map<String, dynamic> data,
  ) {
    return runApiSimple(() async {
      final json = await _client.post(
        ApiEndpoints.adminStudentPaymentPlan(studentId),
        data: data,
      );
      return StudentPaymentPlanDto.fromJson(
        Map<String, dynamic>.from(json?['plan'] as Map? ?? const {}),
      );
    });
  }

  Future<RecordPaymentResult> recordPayment(
    String studentId,
    Map<String, dynamic> data,
  ) {
    return runApiSimple(() async {
      final json = await _client.post(
        ApiEndpoints.adminStudentRecordPayment(studentId),
        data: data,
      );
      return RecordPaymentResult.fromJson(json ?? const {});
    });
  }

  Future<PaymentReminderDto> reminder(String studentId) {
    return runApiSimple(() async {
      final json = await _client.post(
        ApiEndpoints.adminStudentPaymentReminder(studentId),
      );
      return PaymentReminderDto.fromJson(json ?? const {});
    });
  }

  Future<StudentSelfPaymentDto> ownPayments() {
    return runApiSimple(() async {
      final json = await _client.get(ApiEndpoints.studentPayments);
      return StudentSelfPaymentDto.fromJson(json ?? const {});
    });
  }

  Future<Map<String, dynamic>> initiateOnline({double? amount}) {
    return runApiSimple(() async {
      final json = await _client.post(
        ApiEndpoints.studentPaymentsOnlineInitiate,
        data: {
          if (amount != null) 'amount': amount,
        },
      );
      return json ?? const {};
    });
  }

  Future<StudentSelfPaymentDto> confirmOnline({
    required String orderId,
    String? transactionId,
  }) {
    return runApiSimple(() async {
      final json = await _client.post(
        ApiEndpoints.studentPaymentsOnlineConfirm,
        data: {
          'order_id': orderId,
          if (transactionId != null) 'transaction_id': transactionId,
        },
      );
      return StudentSelfPaymentDto(
        plan: json?['plan'] is Map
            ? StudentPaymentPlanDto.fromJson(
                Map<String, dynamic>.from(json!['plan'] as Map),
              )
            : null,
        onlineEnabled: true,
      );
    });
  }
}
