import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/maps_api_failures.dart';
import 'package:excellent_educators_web/features/auth/data/dto/user_dto.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/onboarding/data/dto/onboarding_dtos.dart';

class OnboardingRepository with MapsApiFailures {
  OnboardingRepository(this._client);

  final ApiClient _client;

  Future<List<InterestQuestionDto>> adminInterestQuestions() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.adminInterestQuestions);
      return items
          .whereType<Map>()
          .map(
            (item) => InterestQuestionDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((question) => question.isActive)
          .toList();
    });
  }

  Future<List<InterestQuestionDto>> upsertInterestQuestions(
    List<Map<String, dynamic>> questions,
  ) {
    return runApi(() async {
      final items = await _client.putList(
        ApiEndpoints.adminInterestQuestions,
        data: {'questions': questions},
      );
      return items
          .whereType<Map>()
          .map(
            (item) => InterestQuestionDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    });
  }

  Future<List<ParentQuestionDto>> adminParentQuestions() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.adminParentQuestions);
      return items
          .whereType<Map>()
          .map(
            (item) => ParentQuestionDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((question) => question.isActive)
          .toList();
    });
  }

  Future<List<ParentQuestionDto>> upsertParentQuestions(
    List<Map<String, dynamic>> questions,
  ) {
    return runApi(() async {
      final items = await _client.putList(
        ApiEndpoints.adminParentQuestions,
        data: {'questions': questions},
      );
      return items
          .whereType<Map>()
          .map(
            (item) => ParentQuestionDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    });
  }

  Future<InterestProfileDto> studentInterestProfile() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.studentInterestProfile);
      return InterestProfileDto.fromJson(json!);
    });
  }

  Future<AppUser> submitInterestProfile(List<Map<String, dynamic>> answers) {
    return runApi(() async {
      final json = await _client.post(
        ApiEndpoints.studentInterestProfile,
        data: {'answers': answers},
      );
      return UserDto.fromJson(json!).toEntity();
    });
  }

  Future<ParentIntakeDto> studentParentIntake() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.studentParentIntake);
      return ParentIntakeDto.fromJson(json!);
    });
  }

  Future<AppUser> submitParentIntake(List<Map<String, dynamic>> answers) {
    return runApi(() async {
      final json = await _client.post(
        ApiEndpoints.studentParentIntake,
        data: {'answers': answers},
      );
      return UserDto.fromJson(json!).toEntity();
    });
  }

  Future<AppUser> skipParentIntake() {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.studentParentIntakeSkip);
      return UserDto.fromJson(json!).toEntity();
    });
  }
}
