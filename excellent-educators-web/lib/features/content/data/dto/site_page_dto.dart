class SitePageDto {
  const SitePageDto({
    required this.slug,
    required this.title,
    required this.body,
    this.updatedAt,
  });

  factory SitePageDto.fromJson(Map<String, dynamic> json) {
    return SitePageDto(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }

  final String slug;
  final String title;
  final String body;
  final String? updatedAt;

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'body': body,
      };

  SitePageDto copyWith({String? title, String? body}) {
    return SitePageDto(
      slug: slug,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt,
    );
  }
}

abstract final class SitePageSlugs {
  static const privacy = 'privacy-policy';
  static const terms = 'terms-and-conditions';
  static const refund = 'refund-policy';
  static const contact = 'contact';

  static const all = [privacy, terms, refund, contact];
}
