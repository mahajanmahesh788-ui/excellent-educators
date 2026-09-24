import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/maps_api_failures.dart';
import 'package:excellent_educators_web/features/content/data/dto/site_page_dto.dart';

class SitePageRepository with MapsApiFailures {
  SitePageRepository(this._client);

  final ApiClient _client;

  Future<List<SitePageDto>> fetchPublicAll() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.sitePages);
      return items
          .whereType<Map>()
          .map((item) => SitePageDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<SitePageDto> fetchPublic(String slug) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.sitePage(slug));
      return SitePageDto.fromJson(json!);
    });
  }

  Future<List<SitePageDto>> fetchAdminAll() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.adminSitePages);
      return items
          .whereType<Map>()
          .map((item) => SitePageDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<SitePageDto> updateAdmin(String slug, {required String title, required String body}) {
    return runApi(() async {
      final json = await _client.put(
        ApiEndpoints.adminSitePage(slug),
        data: {'title': title, 'body': body},
      );
      return SitePageDto.fromJson(json!);
    });
  }
}
