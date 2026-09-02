class LoginPagePillarDto {
  const LoginPagePillarDto({
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  factory LoginPagePillarDto.fromJson(Map<String, dynamic> json) {
    return LoginPagePillarDto(
      icon: json['icon'] as String? ?? 'auto_awesome_outlined',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'title': title,
      'body': body,
    };
  }

  LoginPagePillarDto copyWith({String? icon, String? title, String? body}) {
    return LoginPagePillarDto(
      icon: icon ?? this.icon,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}

class LoginPageContentDto {
  const LoginPageContentDto({
    required this.tagline,
    required this.headline,
    required this.description,
    required this.pillars,
    required this.missionQuote,
    required this.formTitle,
    required this.formSubtitle,
    required this.forgotFormTitle,
    required this.forgotFormSubtitle,
  });

  final String tagline;
  final String headline;
  final String description;
  final List<LoginPagePillarDto> pillars;
  final String? missionQuote;
  final String formTitle;
  final String formSubtitle;
  final String forgotFormTitle;
  final String forgotFormSubtitle;

  static const defaults = LoginPageContentDto(
    tagline: 'Building Careers. Creating Leaders.',
    headline: 'Student development\nwith purpose and direction',
    description:
        'Excellent Educators is not a traditional tuition or exam-coaching '
        'institute. We focus on career guidance, personality development, '
        'essential skills and structured student growth.',
    pillars: [
      LoginPagePillarDto(
        icon: 'person_search_outlined',
        title: 'Understand first',
        body: 'We start by understanding each student before shaping their path.',
      ),
      LoginPagePillarDto(
        icon: 'foundation_outlined',
        title: 'Build foundations',
        body: 'A shared base of skills and habits supports everything that follows.',
      ),
      LoginPagePillarDto(
        icon: 'route_outlined',
        title: 'Personalise next',
        body: 'Guidance adapts to strengths, goals and the choices ahead.',
      ),
      LoginPagePillarDto(
        icon: 'insights_outlined',
        title: 'Review progress',
        body: 'Regular feedback keeps development structured and on track.',
      ),
    ],
    missionQuote:
        'Help students understand themselves, build essential skills '
        'and make better-informed decisions for the future.',
    formTitle: 'Welcome back',
    formSubtitle: 'Sign in to track feedback, assessments and your development journey.',
    forgotFormTitle: 'Reset your password',
    forgotFormSubtitle:
        'Enter the email you use to sign in. Students and teachers can use this form.',
  );

  factory LoginPageContentDto.fromJson(Map<String, dynamic> json) {
    final pillars = (json['pillars'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => LoginPagePillarDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return LoginPageContentDto(
      tagline: json['tagline'] as String? ?? defaults.tagline,
      headline: json['headline'] as String? ?? defaults.headline,
      description: json['description'] as String? ?? defaults.description,
      pillars: pillars.isEmpty ? defaults.pillars : pillars,
      missionQuote: json['mission_quote'] as String?,
      formTitle: json['form_title'] as String? ?? defaults.formTitle,
      formSubtitle: json['form_subtitle'] as String? ?? defaults.formSubtitle,
      forgotFormTitle: json['forgot_form_title'] as String? ?? defaults.forgotFormTitle,
      forgotFormSubtitle: json['forgot_form_subtitle'] as String? ?? defaults.forgotFormSubtitle,
    );
  }

  Map<String, dynamic> toAdminUpdateJson() {
    return {
      'tagline': tagline,
      'headline': headline,
      'description': description,
      'pillars': pillars.map((pillar) => pillar.toJson()).toList(),
      'mission_quote': missionQuote,
      'form_title': formTitle,
      'form_subtitle': formSubtitle,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'tagline': tagline,
      'headline': headline,
      'description': description,
      'pillars': pillars.map((pillar) => pillar.toJson()).toList(),
      'mission_quote': missionQuote,
      'form_title': formTitle,
      'form_subtitle': formSubtitle,
      'forgot_form_title': forgotFormTitle,
      'forgot_form_subtitle': forgotFormSubtitle,
    };
  }

  LoginPageContentDto copyWith({
    String? tagline,
    String? headline,
    String? description,
    List<LoginPagePillarDto>? pillars,
    String? missionQuote,
    String? formTitle,
    String? formSubtitle,
    String? forgotFormTitle,
    String? forgotFormSubtitle,
  }) {
    return LoginPageContentDto(
      tagline: tagline ?? this.tagline,
      headline: headline ?? this.headline,
      description: description ?? this.description,
      pillars: pillars ?? this.pillars,
      missionQuote: missionQuote ?? this.missionQuote,
      formTitle: formTitle ?? this.formTitle,
      formSubtitle: formSubtitle ?? this.formSubtitle,
      forgotFormTitle: forgotFormTitle ?? this.forgotFormTitle,
      forgotFormSubtitle: forgotFormSubtitle ?? this.forgotFormSubtitle,
    );
  }
}
