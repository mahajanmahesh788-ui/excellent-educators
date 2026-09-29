<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

class SitePage extends Model
{
    use HasUlids;

    public const SLUG_PRIVACY = 'privacy-policy';

    public const SLUG_TERMS = 'terms-and-conditions';

    public const SLUG_REFUND = 'refund-policy';

    public const SLUG_CONTACT = 'contact';

    public const SLUG_ABOUT = 'about-us';

    public const SLUG_FAQ = 'faq';

    public const SLUG_CHILD_CONSENT = 'child-parental-consent';

    protected $fillable = [
        'slug',
        'title',
        'body',
    ];

    /**
     * @return list<string>
     */
    public static function slugs(): array
    {
        return [
            self::SLUG_PRIVACY,
            self::SLUG_TERMS,
            self::SLUG_REFUND,
            self::SLUG_CONTACT,
            self::SLUG_ABOUT,
            self::SLUG_FAQ,
            self::SLUG_CHILD_CONSENT,
        ];
    }

    public static function findBySlug(string $slug): ?self
    {
        self::ensureDefaults();

        return static::query()->where('slug', $slug)->first();
    }

    /**
     * @return list<self>
     */
    public static function allOrdered(): array
    {
        self::ensureDefaults();

        $pages = static::query()->get()->keyBy('slug');

        return array_values(array_filter(array_map(
            fn (string $slug) => $pages->get($slug),
            self::slugs(),
        )));
    }

    public static function ensureDefaults(): void
    {
        foreach (self::defaultPages() as $page) {
            static::query()->firstOrCreate(
                ['slug' => $page['slug']],
                [
                    'title' => $page['title'],
                    'body' => $page['body'],
                ],
            );
        }
    }

    /**
     * @return list<array{slug: string, title: string, body: string}>
     */
    public static function defaultPages(): array
    {
        $brand = 'Excellent Educators';
        $website = 'https://www.excellenteducators.in';
        $email = 'Excellenteducator555@gmail.com';
        $phone = '+91 85589 51555';
        $updated = '29 September 2026';

        return [
            [
                'slug' => self::SLUG_PRIVACY,
                'title' => 'Privacy Policy',
                'body' => self::privacyBody($brand, $website, $email, $phone, $updated),
            ],
            [
                'slug' => self::SLUG_TERMS,
                'title' => 'Terms & Conditions',
                'body' => self::termsBody($brand, $website, $email, $phone, $updated),
            ],
            [
                'slug' => self::SLUG_REFUND,
                'title' => 'Refund & Cancellation Policy',
                'body' => self::refundBody($brand, $website, $email, $phone, $updated),
            ],
            [
                'slug' => self::SLUG_CONTACT,
                'title' => 'Contact Us',
                'body' => self::contactBody($brand, $website, $email, $phone, $updated),
            ],
            [
                'slug' => self::SLUG_ABOUT,
                'title' => 'About Us',
                'body' => self::aboutBody($brand, $website, $email, $phone, $updated),
            ],
            [
                'slug' => self::SLUG_FAQ,
                'title' => 'Frequently Asked Questions',
                'body' => self::faqBody($brand, $website, $email, $phone, $updated),
            ],
            [
                'slug' => self::SLUG_CHILD_CONSENT,
                'title' => 'Child Safety & Parental Consent',
                'body' => self::childConsentBody($brand, $website, $email, $phone, $updated),
            ],
        ];
    }

    private static function privacyBody(string $brand, string $website, string $email, string $phone, string $updated): string
    {
        return <<<TEXT
PRIVACY POLICY / DIGITAL PERSONAL DATA PROTECTION NOTICE
Excellent Educators

Effective date: {$updated}
Last updated: {$updated}

1. Introduction
Excellent Educators ("{$brand}", "we", "us", or "our") operates {$website} and the related online learning platform, including the public website, Flutter web application, student portal, teacher portal, and admin portal (together, the "Service").

This Privacy Policy and Privacy Notice explains how we collect, use, store, share, retain, and protect personal data in connection with the Service. It is designed to be clear and standalone, and to help users understand what personal data we process and why, in line with India's Digital Personal Data Protection Act, 2023 (DPDP Act) and the Digital Personal Data Protection Rules, 2025, as applicable.

{$brand} generally acts as a Data Fiduciary when it determines the purpose and means of processing personal data of students, parents/guardians, teachers, and authorised staff on the Service.

2. Scope
This Policy applies to personal data processed through:
• our website at {$website};
• the Flutter web application / learning platform;
• student, teacher, and admin portals;
• related communications such as email, SMS, in-app notifications, and WhatsApp service messages where used.

It covers students (typically Classes 6–12), parents/guardians, teachers/mentors, and administrators/sub-admins.

3. Personal data we collect
We collect only the personal data needed to operate the Service. Depending on your role and the features you use, this may include:

A. Account information
• Full name
• Email address
• Mobile / phone number
• WhatsApp number (where provided)
• Password (stored in hashed/secure form; we do not store passwords in plain text)
• Role/account type (student, teacher, admin)
• Student code / internal identifiers
• Login and authentication records

B. Student information
• Class / grade
• Gender (where provided)
• Academic level and batch
• Assigned master teacher(s) / mentor information
• Guardian name and guardian phone (where provided)
• Address (where provided)
• Aptitude / Career Compass assessment answers, status, and results
• Learning journal entries and weekly learning submissions
• Feedback, ratings, and mentor progress notes
• Master-class allotment / usage information
• Payment plan, payment history, payment status, and receipt references

C. Parent / guardian information
• Name (where provided)
• Mobile / email (where provided)
• Relationship to the student (where provided)
• Platform Terms acceptance records for student accounts (version and time, where recorded)
• Parental / guardian consent details where collected through our enrolment or support process (in-app verifiable parental-consent capture is being rolled out)

D. Teacher information
• Name, email, mobile, WhatsApp number (where provided)
• Profile / mentoring profile details
• Roles (for example common teacher / master teacher)
• Availability and leave information
• Class schedule and booking commitments
• Attendance / session activity information related to teaching duties

E. Booking and class information
• Session booking date and time
• Teacher and student linked to a booking
• Reschedule / cancellation related records
• Google Meet or other online meeting links generated for classes
• Join / attendance related records

F. Attendance information
• Attendance status and related session records
• Teacher/student join activity where recorded by the Service
• Class window / reminder activity (for example WhatsApp reminder timing where enabled)

G. Payment information
• Fee amount, payment mode (online/offline), payment date/time
• Payment status and plan status (for example pending, paid, overdue)
• Transaction / order / reference identifiers
• Receipt files or receipt links generated by the platform
• Notes associated with a recorded payment
We do not store complete credit/debit card numbers, CVV, or full UPI credentials on our servers. Where online payments are enabled, payment credentials are processed by authorised payment service providers (for example Razorpay, where configured).

H. Technical information
• Device / browser type
• IP address
• Basic usage and security logs
• Approximate location derived from IP where needed for security or operations
We do not require GPS/device location permission for basic registration or class use. If a future optional location feature is enabled, we will explain it separately at the point of collection.

I. Communications
• Support messages and admin requests
• Service notifications (booking, reminders, payment reminders, account alerts)
• WhatsApp / SMS / email communications sent for Service purposes

J. Feedback and ratings
• Session or monthly feedback ratings
• Written feedback notes where submitted

K. Photos / media
• Profile photos only if/when that feature is enabled and used
We do not use student photos, videos, testimonials, or achievements for marketing, social media, or advertising without a separate, appropriate consent process.

4. Why we collect personal data (purpose)
We process personal data for specified purposes, including:

Data → Purpose
• Name → Identify and manage accounts; display in portals and receipts
• Mobile / WhatsApp → Account communication, reminders, support, and service messages
• Email → Account access, notifications, and support
• Password → Secure authentication
• Class / level / batch → Programme allocation and learning management
• Teacher assignment → Mentoring and class delivery
• Guardian details → Communication and parental oversight for minor students
• Assessment and learning data → Deliver Career Compass / weekly learning and track progress
• Bookings and Meet links → Schedule and run online classes
• Attendance → Track participation and programme administration
• Payment and receipt data → Fee management, payment confirmation, accounting, and refunds where applicable
• Feedback/ratings → Quality improvement and mentoring support
• Technical logs / IP → Security, fraud prevention, troubleshooting, and service reliability
• Terms acceptance and guardian contact details → Support account use, parental oversight, and applicable consent requirements

We do not collect personal data for unspecified or unlimited purposes.

5. Notice at the time of collection
Where practical, we provide a clear notice explaining:
• what personal data is being collected;
• the purpose of processing;
• how to withdraw consent where processing is based on consent;
• how to exercise rights; and
• how to raise a privacy grievance.

Example (account creation):
We collect your name, mobile number, and email address to create and manage your account, provide classes, manage bookings, and communicate important information about your programme.

Example (optional information):
Guardian phone or WhatsApp number may be collected to support communication. Providing optional fields is not required for basic account creation unless programme rules require them.

6. Children's personal data and parental consent
{$brand} is designed for students in Classes 6–12. Many students may be children under applicable law.

Under the DPDP framework, processing a child's personal data generally requires verifiable consent of a parent or lawful guardian, subject to applicable exemptions. Tracking, behavioural monitoring, and targeted advertising directed at children are restricted as provided under applicable law.

Where a student is a minor:
• a parent/guardian should supervise enrolment and ongoing use;
• we ask for guardian name and phone where provided, and may confirm consent through our admissions or support process;
• students accept platform Terms, Privacy, and Refund policies in-app after login;
• we do not use children's data for targeted advertising;
• we do not use behavioural advertising profiles for children.

Please also read our separate Child Safety & Parental Consent page. Today we may hold guardian contact details and student Terms-acceptance records. A fuller in-app parental-consent audit trail (status, method, and related evidence) is being rolled out; until then, parents/guardians may also confirm or raise concerns by contacting us.

7. How we use personal data
We use personal data to:
• create and manage student, teacher, and admin accounts;
• deliver assessments, mentoring, weekly learning, and master classes;
• schedule, run, and support online sessions (including Google Meet where enabled);
• record attendance and related class activity;
• manage fees, payment plans, receipts, reminders, and refunds where applicable;
• send Service communications (including WhatsApp/email/SMS where used);
• improve programme quality and platform reliability;
• protect the Service against misuse and comply with legal obligations.

8. Google Meet and online classes
{$brand} may use Google services (including Google Meet) to facilitate online classes. Information necessary to create or manage a class session—such as meeting link, class date/time, and participant association (teacher/student)—may be processed through such third-party services.

Where Meet links are created through an organisation/admin Google connection, meeting metadata may be processed by Google under Google's terms and privacy practices, in addition to this Policy. We do not include Meet links in certain WhatsApp reminder messages by design, where that restriction is configured in the Service.

9. Payments
Where fees are collected:
• offline payments may be recorded by authorised staff with amount, mode, date, and notes;
• online payments, where enabled, may be processed by authorised payment gateways;
• receipts may be generated and stored for download through the platform (for example via Settings → Payment).

{$brand} does not directly store complete credit/debit card details or CVV. Payment providers process sensitive payment credentials on their systems.

10. Sharing of personal data
We do not sell personal data.

We may share personal data only as needed with:
• assigned teachers/mentors and authorised staff, to teach and support the student;
• service providers acting as processors/service vendors (hosting, email/SMS, WhatsApp business messaging interfaces, video meetings, payment gateways, storage), under confidentiality and security expectations;
• authorities when required by law or to protect rights, safety, or the integrity of the Service.

Third-party services we may use (only where actually configured) include examples such as Google (including Meet), payment gateways (for example Razorpay), hosting/infrastructure providers, and communication providers. Each processes data only as needed for their service and under their own policies in addition to ours.

11. Cookies and similar technologies
We may use essential cookies/session storage for:
• login and authentication;
• session security;
• remembering basic preferences needed for the Service to function.

We do not currently rely on advertising cookies for targeted ads to students. If we later use analytics or advertising cookies, we will update this Policy and, where required, seek appropriate consent.

12. Data security
We use reasonable technical and organisational measures appropriate to the nature of the data and our Service, which may include:
• HTTPS for data in transit;
• password hashing;
• authentication and role-based access controls;
• admin permission controls;
• API authentication;
• secure integration with payment and meeting providers;
• server and database access controls;
• backups;
• audit/activity logging where implemented.

No online service can guarantee absolute security. Please keep credentials confidential and use a strong password.

13. Data retention and deletion
We retain personal data only for as long as needed for the purposes described, or as required for legal, accounting, dispute, or security reasons.

Illustrative retention approach:
• Active account data → while the account remains active and for a reasonable period afterwards
• Learning, attendance, and booking records → for academic/administrative purposes and legitimate history needs
• Payment and receipt records → for accounting, tax, dispute, and legal requirements
• Consent / parental consent records → for as long as needed to demonstrate compliance
• Security/audit logs → for security and operational needs
• Backups → according to backup retention cycles

After an account deletion request is approved, we delete or anonymise personal data that is no longer required. Some records (especially payment, dispute, or legally required records) and backup copies may remain for a limited period where necessary. We will not promise immediate erasure of every copy if law or backup systems prevent that.

14. Your rights (Data Principal rights)
Subject to applicable law, you may request:
• access to your personal data;
• correction of inaccurate or incomplete personal data;
• erasure/deletion where applicable;
• withdrawal of consent where processing is based on consent;
• information about processing;
• grievance / complaint handling.

You may also update certain profile details inside the platform where that feature is available.

To make a privacy request, email {$email} with:
• your name and role (student / parent / teacher);
• registered email or mobile;
• request type (access / correction / deletion / withdraw consent / complaint / other);
• a brief description.

We may need to verify identity before fulfilling a request.

15. Withdrawal of consent
Where processing is based on consent, you may withdraw consent by contacting us. Withdrawal does not affect processing already completed lawfully. If consent is required to provide core Service features, withdrawal may mean we cannot continue those features or the account.

16. Privacy and grievance contact
Privacy / Grievance Contact
• Organisation: Excellent Educators
• Email: {$email}
• Phone / WhatsApp: {$phone}
• Website: {$website}

We aim to acknowledge and respond to privacy grievances within a reasonable period and through an effective redressal process. If you are not satisfied after our response, you may pursue remedies available under applicable law, including before the Data Protection Board of India where applicable.

17. Cross-border / service provider processing
Our Service may use cloud hosting or processors that store or process data in India or other locations depending on configuration. We take reasonable steps to ensure appropriate safeguards and contractual/security arrangements with processors who handle personal data on our behalf.

18. Changes to this Policy
We may update this Privacy Policy from time to time. The “Last updated” date will change when we do. For material changes, we may provide additional notice through the platform or email where practical. Continued use of the Service after updates means you accept the revised Policy, subject to applicable law and consent requirements.

19. Contact
Questions about this Privacy Policy: {$email} | {$phone}
Website: {$website}

Related documents
• Terms & Conditions
• Refund & Cancellation Policy
• Child Safety & Parental Consent
• Contact Us
TEXT;
    }

    private static function childConsentBody(string $brand, string $website, string $email, string $phone, string $updated): string
    {
        return <<<TEXT
CHILD SAFETY & PARENTAL / GUARDIAN CONSENT
Excellent Educators

Last updated: {$updated}

1. Why this page exists
{$brand} serves students in Classes 6–12. Many learners are children. India's Digital Personal Data Protection Act, 2023 and related Rules require special care for children's personal data, including verifiable parental/lawful guardian consent where applicable, and restrictions on tracking/targeted advertising directed at children.

This page explains how {$brand} approaches child safety and parental consent on the Service.

2. Who is a child for this purpose
For this Policy, a “child” means a student who is under the applicable age under Indian data protection law. Parents/lawful guardians are responsible for supervising a minor student's enrolment and use of the Service.

3. What we ask parents/guardians to consent to
Where required, parent/guardian consent relates to processing personal data needed to:
• create and manage the student account;
• allocate level/batch and mentors;
• deliver assessments, weekly learning, mentoring, and master classes;
• manage bookings, attendance, and online class links (for example Google Meet);
• manage fees, receipts, and payment reminders;
• send necessary Service communications.

Consent for core education services is separate from any optional marketing/publicity consent (for example using a student's photo or testimonial on social media). Optional publicity requires a separate, clear consent and is not implied by account creation.

4. How consent is handled today
Today, {$brand} may hold:
• Parent/Guardian name and mobile (where provided on the student profile)
• Student platform Terms / Privacy / Refund acceptance (version and time after student login)
• Consent or acknowledgement confirmed through admissions or support contact when needed

A fuller in-app verifiable parental-consent capture (including consent status, method, policy version, and related audit information such as IP/user agent where recorded) is being rolled out. Until that feature is live, parents/guardians should supervise enrolment and contact us if a child account was created without appropriate consent.

A simple unchecked box without meaningful notice is not our intended standard for child-related processing.

5. What we do not do with children's data
• We do not sell children's personal data.
• We do not use children's data for targeted behavioural advertising.
• We do not use student photos/videos for marketing without separate appropriate consent.
• We limit access to student data to authorised teachers/staff who need it for teaching and administration.

6. Parent/guardian responsibilities
Parents/guardians should:
• provide accurate guardian contact details where requested;
• supervise the student's use of the Service;
• keep login credentials confidential;
• contact us promptly if they believe a child account was created without appropriate consent.

7. Withdrawal and questions
A parent/guardian may contact us to withdraw consent where processing is consent-based, request access/correction/deletion where applicable, or raise a concern.

Contact
• Email: {$email}
• Phone / WhatsApp: {$phone}
• Website: {$website}

Also see our Privacy Policy for full details of data processing, retention, security, and rights.
TEXT;
    }

    private static function termsBody(string $brand, string $website, string $email, string $phone, string $updated): string
    {
        return <<<TEXT
Last updated: {$updated}

These Terms & Conditions ("Terms") govern access to and use of Excellent Educators' website {$website} and learning platform (the "Service"). By creating an account, making a payment, or using the Service, you agree to these Terms.

1. About the Service
{$brand} offers career guidance, personality and skill development, mentoring, assessments, weekly learning content, and live online sessions for students in Classes 6–12. We are not a traditional tuition or exam-coaching institute. Programme structure (including Level 1 start for new students, weekly common classes, and monthly master classes) may evolve as we improve the Service.

2. Eligibility and accounts
• Students, parents/guardians, teachers, and authorised staff may use the Service as permitted by their account type.
• You must provide accurate registration information and keep it up to date.
• You are responsible for all activity under your login. Do not share passwords.
• Parents/guardians are responsible for supervising a minor student’s use of the Service.

3. Programme participation
• Students are expected to complete assigned assessments, weekly learning, and attend booked sessions on time.
• Mentors may record progress observations and ratings as part of the development model.
• Session slots depend on teacher availability. Missed sessions without timely notice may not be automatically rescheduled.
• Online sessions may be delivered through Google Meet or similar tools.

4. Acceptable use
You agree not to:
• misuse the platform, disrupt sessions, or harass mentors, staff, or other users;
• upload unlawful, harmful, or infringing content;
• attempt to access data or areas you are not authorised to use;
• copy, resell, or redistribute learning content except for personal educational use within the enrolled programme.

5. Fees and payments
• Programme fees, if any, are shown at the time of enrolment or payment.
• Offline payments may be recorded by authorised staff. Online payments through a third-party gateway (for example Razorpay) apply only when that gateway is configured and enabled on the Service. Where a gateway is used, you also accept the gateway’s applicable terms.
• Prices and inclusions may change for future enrolments. Refunds and cancellations are governed by our Refund & Cancellation Policy (limited eligibility — not a blanket “non-refundable” rule). Please read that policy before paying.

6. Intellectual property
Learning materials, assessments, branding, and platform software remain the property of {$brand} or its licensors. Enrolment grants a limited, non-transferable licence to use materials for the enrolled student’s education only.

7. Disclaimers
• Mentoring and career guidance support development; they do not guarantee specific school marks, admission outcomes, or career results.
• The Service is provided on an “as available” basis. We aim for reliable access but do not guarantee uninterrupted operation.

8. Limitation of liability
To the fullest extent permitted by law, {$brand} is not liable for indirect or consequential losses arising from use of the Service. Our total liability for a claim relating to a paid enrolment is limited to the fees paid for the affected period, except where liability cannot be limited by law.

9. Suspension and termination
We may suspend or terminate access for breach of these Terms, non-payment, or misuse. You may stop using the Service at any time; fee outcomes are governed by the Refund & Cancellation Policy.

10. Changes to the Terms
We may update these Terms. The updated version will apply from the stated “Last updated” date. Material changes may be communicated through the platform or email where practical.

11. Governing law
These Terms are governed by the laws of India. Courts in India shall have jurisdiction, without limiting any mandatory consumer protections that apply.

12. Contact
{$email} | {$phone}
{$website}
TEXT;
    }

    private static function refundBody(string $brand, string $website, string $email, string $phone, string $updated): string
    {
        return <<<TEXT
Last updated: {$updated}

This Refund & Cancellation Policy explains how cancellations, refunds, and payment issues are handled for Excellent Educators programmes purchased through {$website} or our platform. It is intended to meet common payment-partner expectations (including Razorpay onboarding) while remaining clear for families.

1. Scope
This policy applies to paid programme fees, subscription or enrolment charges, and related online payments collected by {$brand}. Free trial or complimentary access (if offered) is not refundable as cash.

2. Order confirmation
After a successful payment, you will normally receive confirmation through the platform and/or email or SMS. Keep your payment reference for support requests.

3. Cancellation by the customer
• You may request cancellation by contacting {$email} or {$phone} with the student name, registered email/phone, and payment reference.
• If a request is made before the programme start date / first paid service delivery (whichever applies to your plan), we will review eligibility for a full or partial refund.
• After mentoring, assessments, weekly learning access, or paid sessions have begun, refunds are generally not available except as stated below or required by law.

4. Refund eligibility
Refunds may be considered when:
• a duplicate payment was charged in error;
• payment succeeded but access was not provisioned due to a verified technical fault on our side, and we cannot restore access within a reasonable time;
• we cancel a paid programme cohort or paid service before delivery and cannot offer a suitable alternative.

Refunds are generally not available for:
• change of mind after programme access or paid sessions have started;
• missed sessions caused by the student/parent without timely rescheduling as per programme rules;
• dissatisfaction with mentoring outcomes, since guidance is developmental and results vary by student effort and participation;
• partial use of digital content that has already been unlocked.

5. How refunds are processed
• Approved refunds are returned to the original payment method where possible through our payment partner.
• Processing time is typically 5–10 business days after approval, depending on the bank or UPI provider.
• We may ask for identity and payment proof before approving a refund.

6. Rescheduling sessions
Where a live session is cancelled by us, we will offer a reschedule. Customer-side no-shows may not qualify for refund or automatic makeup sessions.

7. Chargebacks
If you open a chargeback or dispute with your bank, please also contact us so we can help resolve the issue. Unresolved misuse of chargebacks may lead to account suspension.

8. Contact for refunds
Email: {$email}
Phone: {$phone}
Website: {$website}

Please include: student full name, registered contact, payment date/amount, transaction ID, and reason for the request.
TEXT;
    }

    private static function aboutBody(string $brand, string $website, string $email, string $phone, string $updated): string
    {
        return <<<TEXT
ABOUT EXCELLENT EDUCATORS
Last updated: {$updated}

Discover what makes you different.

{$brand} is not a traditional tuition or exam-coaching institute. We are a mentoring and student-growth platform for Classes 6–12 — focused on career guidance, personality development, essential skills, and structured progress with dedicated mentors.

Our mission
Help every student understand themselves, build real-world capabilities, and explore the future with clarity — guided by mentors who stay on the journey, not a revolving door of tutors.

Who we are for
• Students in Classes 6–12 who want growth beyond marks alone
• Parents and guardians who want visible progress, mentoring, and clear communication
• Schools and partners who value personality, skills, and career readiness

What makes us different
• Mentor-first — one guide for the fuller journey, not random sessions
• Weekly rhythm — learning journal, class, and review that prove the week
• Live 1:1 — introduction calls and master classes that fit real school weeks
• Progress you can see — feedback, attendance, and learning history in one place
• Online and organised — bookings, Google Meet classes, payments, and receipts on one platform

How your journey works
1. Discover yourself
Uncover strengths, learning styles, and natural curiosity through guided discovery and structured onboarding.

2. Build your skills
Develop essential capabilities — communication, critical thinking, discipline, and confident habits.

3. Explore your future
Map academic and career pathways with clarity, aligned to the student’s profile and interests.

4. Grow with guidance
Learn with dedicated master mentors who review weekly progress and guide the next step.

What students experience on the platform
• Personal dashboard and learning journey
• Session booking around real availability
• Live online classes (including Google Meet where enabled)
• Weekly learning and mentor feedback
• Master classes and progress tracking
• Clear payment status, history, and downloadable receipts
• Supportive Settings for Privacy, FAQ, and account help

Our promise to families
We keep mentoring personal, schedules practical, and progress visible. We protect student data carefully and involve parents/guardians where a learner is a minor. For details, see our Privacy Policy and Child Safety & Parental Consent pages.

Leadership note
{$brand} is built with a founder-led commitment to student growth and mentoring quality. Programme design may evolve as we improve the experience for students and families — always with clarity and care.

Get in touch
We would love to hear from you — admissions, programme questions, or partnership ideas.

• Website: {$website}
• Email: {$email}
• Phone / WhatsApp: {$phone}

Explore more
• Privacy Policy
• Terms & Conditions
• Refund & Cancellation Policy
• Child Safety & Parental Consent
• FAQ
• Contact Us
TEXT;
    }

    private static function faqBody(string $brand, string $website, string $email, string $phone, string $updated): string
    {
        return <<<TEXT
Last updated: {$updated}

1. Admissions & Enrollment
Q: Which classes and academic boards does {$brand} cater to?
A: {$brand} provides specialized coaching for students from Classes 6 through 12 across CBSE, ICSE, and recognized State Boards. We also offer integrated foundation and competitive batches for engineering (JEE Main/Advanced) and medical (NEET) entrance exams.

Q: How do I enroll or apply for admission?
A: You can apply online through our official website ({$website}) or contact our admissions desk via call/WhatsApp at {$phone} or email at {$email}. Our academic counselors will guide you through batch availability, course syllabus, and fee structure.

Q: Is there an entrance test or diagnostic assessment before admission?
A: Yes, we conduct an initial Aptitude and Diagnostic Assessment to understand the student's current conceptual strengths, learning pace, and areas for improvement. This helps us place the student in the most suitable batch and customize their academic road-map.

Q: What are the batch sizes and student-to-mentor ratios?
A: We maintain small, focused batch sizes (typically 15–20 students per batch) to ensure every student receives individual attention, active engagement, and timely doubt clarification from the faculty.

Q: Can a student join mid-session or switch between batches?
A: Yes, mid-session admissions are accepted subject to seat availability. Backlog recovery sessions and recorded foundation lectures are provided to help new students catch up smoothly. Batch transfers (such as morning to evening batches) can be requested through administration.

2. Academics & Teaching Methodology
Q: What is the teaching pedagogy at {$brand}?
A: Our pedagogy is concept-first and outcome-driven. Every topic is taught from fundamental principles followed by real-world applications, graded practice problems, weekly revision drills, and high-yield exam question patterns.

Q: How are student doubts resolved?
A: We offer dedicated daily Doubt Clearing Sessions both during and after live classes. Students can also submit doubts directly via their student portal or reach out to faculty during scheduled 1-on-1 office hours.

Q: Are study materials, workbooks, and question banks provided?
A: Yes, all enrolled students receive comprehensive, professionally curated study packages, chapter-wise modular theory notes, formula handbooks, previous years' solved question banks, and exhaustive practice worksheets.

Q: How frequently are tests and evaluations conducted?
A: Regular evaluations include Weekly Topic Tests, Fortnightly Chapter Assessments, and Full-Length Simulated Term Exams designed in strict accordance with the latest board and competitive examination blueprints. Detailed performance analytics and rank lists are published after each test.

Q: Are 1-on-1 personalized tutoring options available?
A: Yes, in addition to regular small group batches, we provide customized 1-on-1 intensive mentoring for students who require focused attention, accelerated learning, or specific subject remediation.

3. Online Classes & Technical Requirements
Q: How do live online classes take place?
A: Live interactive sessions are conducted over secure, high-definition conferencing platforms (such as Google Meet). Students can join directly from their Student Dashboard with a single click at the scheduled time.

Q: What devices and technical setup do I need to attend classes?
A: A desktop computer, laptop, or tablet (with a modern browser such as Chrome or Edge) and a reliable broadband internet connection (at least 5–10 Mbps). Earphones or a headset with a microphone are recommended for interactive participation.

Q: What if a student misses a live session?
A: Complete high-definition session recordings and teacher's annotated whiteboard lecture notes are archived in the student portal within 24 hours of the class. Students can replay recorded lectures anytime for revision.

Q: What happens if a class is rescheduled due to technical issues or faculty leave?
A: In the rare event of a schedule adjustment, parents and students receive advance notification via WhatsApp and SMS alerts. Compensatory makeup classes are arranged at a mutually convenient schedule.

4. Fee Structure, Payments & Receipts
Q: What payment options and plans are available?
A: Fee plans are set by the institute (for example full payment or partial/instalment plans where offered). Your assigned plan and amounts appear in the student portal under Settings → Payment.

Q: Which payment modes are accepted?
A: Offline payments (such as UPI transfer, bank transfer, or other modes accepted by the institute) are recorded by authorised staff. Card/net-banking online checkout through a payment gateway is available only when that gateway is configured and enabled. Until then, pay as directed by the institute and keep your payment reference for support.

Q: How do I view my fee status and download official payment receipts?
A: Log in to your student portal and navigate to Settings → Payment. For completed transactions, you can preview and download an official fee receipt where generated.

Q: What is the institute's refund and cancellation policy?
A: Refunds follow our Refund & Cancellation Policy. Eligibility is limited (for example before programme start / first paid service delivery in some cases, or for duplicate charges and certain institute-side failures). After programme access or paid sessions have begun, refunds are generally not available except as stated in that policy or required by law. Please read the Refund & Cancellation Policy for full terms.

Q: Are there sibling discounts or merit-based scholarships?
A: Any concession, scholarship, or sibling arrangement is decided case-by-case by the institute. Ask admissions or support ({$email} / {$phone}) about current options for your family.

5. Parent Engagement & Progress Tracking
Q: How are parents kept informed of their child's academic progress?
A: Progress tools available in the platform (such as bookings, attendance records, learning journal, and mentor feedback where used) help families stay informed. Parents/guardians should use the guardian contact details on the student profile and reach support or faculty through WhatsApp ({$phone}) or email ({$email}) for updates. Automated parent scorecards and alerts may expand over time.

Q: Are Parent-Teacher Meetings (PTMs) conducted regularly?
A: Mentors and staff can discuss progress by appointment. Formal PTM schedules, when offered, are communicated by the institute. Parents may also request a discussion through support.

Q: How can parents contact teachers or the academic director?
A: Parents can contact us via WhatsApp ({$phone}), email ({$email}), or the support desk. Please include the student name and registered phone number.

6. Account Security, Privacy & Child Safety
Q: How do I change or reset my student account password?
A: Students can update their password under Profile → Account Security → Change Password. If you forget your password, use the "Forgot Password" link on the login page or contact support for a secure reset link.

Q: How is student personal data protected?
A: We take privacy seriously and design the Service with India's Digital Personal Data Protection (DPDP) framework in mind. We use reasonable safeguards such as HTTPS in transit, hashed passwords, authentication, and role-based access. We do not claim that every personal field is encrypted at rest. Details are in our Privacy Policy and Child Safety & Parental Consent pages. Privacy requests: {$email}.

Q: Can multiple family members access the student account?
A: Each student has a unique login. Do not share passwords. Parents/guardians should supervise minors and use guardian contact details plus support channels for payment and progress questions rather than sharing the student’s password.

7. Contact & Helpdesk Support
Q: What are the support desk operating hours?
A: Our academic and administrative support desk operates Monday through Saturday, 9:00 AM to 7:00 PM IST. Emergency class assistance during evening batches is also monitored.

Q: How do I contact the institute for immediate assistance?
A: You can reach us via:
• Email: {$email}
• Call & WhatsApp: {$phone}
• Official Website: {$website}
Please mention the student's name, registered phone number, and class for expedited resolution.
TEXT;
    }

    private static function contactBody(string $brand, string $website, string $email, string $phone, string $updated): string
    {
        return <<<TEXT
Last updated: {$updated}

We would love to hear from you. Whether you are a parent, student, or school partner, the {$brand} team can help with admissions, programme questions, account support, payment issues, and privacy requests.

Contact details
• Email: {$email}
• Phone / WhatsApp: {$phone}
• Website: {$website}

Privacy & grievance contact
For privacy requests (access, correction, deletion, withdraw consent) or privacy complaints, email {$email} with your name, registered contact, and request type. We aim to respond through an effective grievance process within a reasonable period.

What to include in your message
• Your name and role (parent/guardian or student)
• Student name and class (6–12)
• Registered email or phone used on the platform
• A short description of your question (admissions, booking, learning access, payment/refund, privacy, or technical issue)
• Payment reference, if your query is about fees or refunds

Response time
We aim to respond within 1–2 business days. Urgent session or access issues are prioritised where possible.

Admissions
Admissions are open for Classes 6–12. You can also explore our approach and book an appointment through {$website}.

Support hours
Support is generally available on business days. Messages received outside these hours are handled on the next business day.
TEXT;
    }
}
