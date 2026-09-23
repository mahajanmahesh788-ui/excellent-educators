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
}

class LoginPageTrustSignalDto {
  const LoginPageTrustSignalDto({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  factory LoginPageTrustSignalDto.fromJson(Map<String, dynamic> json) {
    return LoginPageTrustSignalDto(
      icon: json['icon'] as String? ?? 'verified_outlined',
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'value': value,
      'label': label,
    };
  }
}

class LoginPageStoryDto {
  const LoginPageStoryDto({
    required this.title,
    required this.body,
    required this.imageUrl,
    this.imageOnLeft = true,
  });

  final String title;
  final String body;
  final String imageUrl;
  final bool imageOnLeft;

  factory LoginPageStoryDto.fromJson(Map<String, dynamic> json) {
    return LoginPageStoryDto(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      imageOnLeft: json['image_on_left'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'image_on_left': imageOnLeft,
    };
  }
}

class LoginPageTestimonialDto {
  const LoginPageTestimonialDto({
    required this.quote,
    required this.attribution,
    this.role,
  });

  final String quote;
  final String attribution;
  final String? role;

  factory LoginPageTestimonialDto.fromJson(Map<String, dynamic> json) {
    return LoginPageTestimonialDto(
      quote: json['quote'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quote': quote,
      'attribution': attribution,
      'role': role,
    };
  }
}

class LoginPageContentDto {
  const LoginPageContentDto({
    required this.tagline,
    required this.headline,
    required this.description,
    required this.pillars,
    required this.trustSignals,
    required this.whyHeading,
    required this.stories,
    required this.testimonialsHeading,
    required this.testimonials,
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
  final List<LoginPageTrustSignalDto> trustSignals;
  final String? whyHeading;
  final List<LoginPageStoryDto> stories;
  final String? testimonialsHeading;
  final List<LoginPageTestimonialDto> testimonials;
  final String? missionQuote;
  final String formTitle;
  final String formSubtitle;
  final String forgotFormTitle;
  final String forgotFormSubtitle;

  static const defaults = LoginPageContentDto(
    tagline: 'Student Growth & Mentorship',
    headline: 'Discover what makes you different.',
    description:
        'Excellent Educators is not a traditional tuition or exam-coaching '
        'institute. We focus on career guidance, personality development, '
        'essential skills and structured student growth.',
    trustSignals: [
      LoginPageTrustSignalDto(
        icon: 'verified_outlined',
        value: 'Mentor first',
        label: 'one guide for the full journey',
      ),
      LoginPageTrustSignalDto(
        icon: 'star_outline',
        value: 'Weekly rhythm',
        label: 'journal, class, and review',
      ),
      LoginPageTrustSignalDto(
        icon: 'public_outlined',
        value: 'Live 1:1',
        label: 'intro calls and master classes',
      ),
    ],
    whyHeading: 'How Your Journey Works',
    pillars: [
      LoginPagePillarDto(
        icon: 'lightbulb_outline',
        title: 'Discover Yourself',
        body:
            'Uncover innate strengths, learning styles, and natural curiosity through guided discovery.',
      ),
      LoginPagePillarDto(
        icon: 'auto_awesome',
        title: 'Build Your Skills',
        body:
            'Develop essential real-world capabilities — communication, critical thinking, and disciplined habits.',
      ),
      LoginPagePillarDto(
        icon: 'rocket_launch_outlined',
        title: 'Explore Your Future',
        body:
            'Map genuine academic and career pathways tailored to your personalized profile with total clarity.',
      ),
      LoginPagePillarDto(
        icon: 'school_outlined',
        title: 'Grow With Guidance',
        body:
            'Learn 1:1 with dedicated master mentors who review your weekly progress and guide your evolution.',
      ),
    ],
    stories: [
      LoginPageStoryDto(
        title: 'Sessions that fit real weeks',
        body:
            'Book an introduction call or a master class around school hours — not the other way around. One link, one teacher, one focused slot.',
        imageUrl:
            'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1400&q=80',
        imageOnLeft: true,
      ),
      LoginPageStoryDto(
        title: 'Mentors who stay on the path',
        body:
            'The same faculty follows the student from first conversation through weekly learning. Guidance is personal, not a revolving door of tutors.',
        imageUrl:
            'https://images.unsplash.com/photo-1577896851231-70ef18881754?auto=format&fit=crop&w=1400&q=80',
        imageOnLeft: false,
      ),
      LoginPageStoryDto(
        title: 'A journal that proves the week',
        body:
            'Each week has a video, questions, and a written trail. Students see what they finished. Mentors see where to push next.',
        imageUrl:
            'https://images.unsplash.com/photo-1456513080080-77db1ea6bb6f?auto=format&fit=crop&w=1400&q=80',
        imageOnLeft: true,
      ),
    ],
    testimonialsHeading: 'Voices from our community',
    testimonials: [
      LoginPageTestimonialDto(
        quote:
            'The monthly notes finally told us what to work on at home. We stopped guessing.',
        attribution: 'Kavita',
        role: 'Parent',
      ),
      LoginPageTestimonialDto(
        quote:
            'My introduction call felt like a real conversation. After that, the weekly journal made sense.',
        attribution: 'Arjun',
        role: 'Student',
      ),
      LoginPageTestimonialDto(
        quote:
            'I can see attendance, journal weeks, and ratings in one place. Mentoring is easier to do well.',
        attribution: 'Meera',
        role: 'Master Teacher',
      ),
      LoginPageTestimonialDto(
        quote:
            'He started showing up prepared. The structure did more than extra tuition ever did.',
        attribution: 'Sanjay',
        role: 'Parent',
      ),
    ],
    missionQuote:
        'Help students understand themselves, build essential skills '
        'and make better-informed decisions for the future.',
    formTitle: 'Welcome back',
    formSubtitle:
        'Sign in to track feedback, assessments and your development journey.',
    forgotFormTitle: 'Reset your password',
    forgotFormSubtitle:
        'Enter the email you use to sign in. Students and teachers can use this form.',
  );

  factory LoginPageContentDto.fromJson(Map<String, dynamic> json) {
    final pillars = (json['pillars'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              LoginPagePillarDto.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    final hasTrustKey = json.containsKey('trust_signals');
    final hasStoriesKey = json.containsKey('stories');
    final hasTestimonialsKey = json.containsKey('testimonials');
    final trustSignals = (json['trust_signals'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => LoginPageTrustSignalDto.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
    final stories = (json['stories'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              LoginPageStoryDto.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    final testimonials = (json['testimonials'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => LoginPageTestimonialDto.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();

    return LoginPageContentDto(
      tagline: json['tagline'] as String? ?? defaults.tagline,
      headline: json['headline'] as String? ?? defaults.headline,
      description: json['description'] as String? ?? defaults.description,
      pillars: pillars.isEmpty ? defaults.pillars : pillars,
      trustSignals: (!hasTrustKey && trustSignals.isEmpty)
          ? defaults.trustSignals
          : trustSignals,
      whyHeading: json.containsKey('why_heading')
          ? json['why_heading'] as String?
          : defaults.whyHeading,
      stories: (!hasStoriesKey && stories.isEmpty)
          ? defaults.stories
          : stories,
      testimonialsHeading: json.containsKey('testimonials_heading')
          ? json['testimonials_heading'] as String?
          : defaults.testimonialsHeading,
      testimonials: (!hasTestimonialsKey && testimonials.isEmpty)
          ? defaults.testimonials
          : testimonials,
      missionQuote: json['mission_quote'] as String?,
      formTitle: json['form_title'] as String? ?? defaults.formTitle,
      formSubtitle: json['form_subtitle'] as String? ?? defaults.formSubtitle,
      forgotFormTitle:
          json['forgot_form_title'] as String? ?? defaults.forgotFormTitle,
      forgotFormSubtitle:
          json['forgot_form_subtitle'] as String? ??
          defaults.forgotFormSubtitle,
    );
  }

  Map<String, dynamic> toAdminUpdateJson() {
    return {
      'tagline': tagline,
      'headline': headline,
      'description': description,
      'pillars': pillars.map((pillar) => pillar.toJson()).toList(),
      'trust_signals': trustSignals.map((item) => item.toJson()).toList(),
      'why_heading': whyHeading,
      'stories': stories.map((item) => item.toJson()).toList(),
      'testimonials_heading': testimonialsHeading,
      'testimonials': testimonials.map((item) => item.toJson()).toList(),
      'mission_quote': missionQuote,
      'form_title': formTitle,
      'form_subtitle': formSubtitle,
    };
  }
}
