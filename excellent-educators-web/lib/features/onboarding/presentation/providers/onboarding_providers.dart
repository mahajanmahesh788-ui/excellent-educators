import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/onboarding/data/dto/onboarding_dtos.dart';
import 'package:excellent_educators_web/features/onboarding/data/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(apiClientProvider));
});

final adminInterestQuestionsProvider =
    FutureProvider.autoDispose<List<InterestQuestionDto>>((ref) {
  return ref.watch(onboardingRepositoryProvider).adminInterestQuestions();
});

final adminParentQuestionsProvider =
    FutureProvider.autoDispose<List<ParentQuestionDto>>((ref) {
  return ref.watch(onboardingRepositoryProvider).adminParentQuestions();
});

final studentInterestProfileProvider =
    FutureProvider.autoDispose<InterestProfileDto>((ref) {
  return ref.watch(onboardingRepositoryProvider).studentInterestProfile();
});

final studentParentIntakeProvider =
    FutureProvider.autoDispose<ParentIntakeDto>((ref) {
  return ref.watch(onboardingRepositoryProvider).studentParentIntake();
});
