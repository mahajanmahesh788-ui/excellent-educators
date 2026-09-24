import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/content/data/dto/site_page_dto.dart';
import 'package:excellent_educators_web/features/content/data/site_page_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sitePageRepositoryProvider = Provider<SitePageRepository>((ref) {
  return SitePageRepository(ref.watch(apiClientProvider));
});

final publicSitePageProvider =
    FutureProvider.autoDispose.family<SitePageDto, String>((ref, slug) {
  return ref.watch(sitePageRepositoryProvider).fetchPublic(slug);
});

final adminSitePagesProvider =
    FutureProvider.autoDispose<List<SitePageDto>>((ref) {
  return ref.watch(sitePageRepositoryProvider).fetchAdminAll();
});
