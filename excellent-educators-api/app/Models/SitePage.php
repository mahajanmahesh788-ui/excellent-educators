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
        $updated = '24 September 2026';

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
        ];
    }

    private static function privacyBody(string $brand, string $website, string $email, string $phone, string $updated): string
    {
        return <<<TEXT
Last updated: {$updated}

Excellent Educators ("{$brand}", "we", "us", or "our") operates the website {$website} and the related student, parent, teacher, and admin platform (together, the "Service"). This Privacy Policy explains how we collect, use, store, and protect personal information when you use our Service.

1. Who we are
{$brand} provides career guidance, personality development, skill development, and structured mentoring for students in Classes 6–12. Our programmes include assessments (such as Career Compass), weekly learning, mentor reviews, and live online sessions (including Google Meet where enabled).

2. Information we collect
We may collect:
• Account details: name, email address, phone number, password (stored securely), student code, class/grade, gender, guardian name and phone (where provided), and profile information.
• Learning and mentoring data: assessment answers and results, weekly assignment responses, learning journal entries, attendance, session bookings, mentor notes, and progress ratings.
• Session and communication data: booking times, meeting links, and related notifications.
• Payment and billing data: payment status, transaction references, and related records processed through our payment partner (for example Razorpay). We do not store full card or UPI credentials on our servers.
• Technical data: device/browser type, IP address, approximate location derived from IP, and basic usage logs needed to keep the Service secure and reliable.

3. How we use information
We use personal information to:
• create and manage student, parent/guardian, teacher, and admin accounts;
• deliver assessments, mentoring, weekly learning, master classes, and progress tracking;
• schedule and run online sessions;
• process payments, invoices, and refunds where applicable;
• send service notifications (for example booking confirmations, reminders, and important account alerts);
• improve programme quality, prevent misuse, and meet legal or regulatory obligations.

4. Sharing of information
We do not sell personal information. We may share information with:
• mentors and authorised staff assigned to the student, so they can teach and support the learner;
• service providers who help us operate the platform (hosting, email/SMS, video meetings, and payment gateways), under appropriate confidentiality and security expectations;
• authorities when required by law or to protect rights, safety, or the integrity of the Service.

5. Data retention
We retain account and learning records for as long as the account is active and for a reasonable period afterwards to support academic history, dispute handling, audits, and legal requirements. You may request deletion of account data subject to legitimate retention needs (for example payment or dispute records).

6. Security
We use reasonable technical and organisational measures to protect personal information. No online service can guarantee absolute security; please keep login credentials confidential and use a strong password.

7. Children’s information
Our Service is designed for students in Classes 6–12 and may involve parent/guardian accounts. Where a student is a minor, we expect a parent or guardian to supervise enrolment and use of the account. If you believe a child has provided information without appropriate consent, contact us and we will take reasonable steps to address it.

8. Your choices
Subject to applicable law, you may request access to, correction of, or deletion of personal information connected to your account by contacting us. You may also update certain profile details inside the platform where that feature is available.

9. Third-party services
The Service may integrate third-party tools such as Google Meet and payment gateways. Their use of data is governed by their own policies in addition to this Privacy Policy.

10. Changes
We may update this Privacy Policy from time to time. The “Last updated” date will change when we do. Continued use of the Service after updates means you accept the revised policy.

11. Contact
Questions about privacy: {$email} | {$phone}
Website: {$website}
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
• Payments may be processed by third-party gateways such as Razorpay. By paying, you also accept the gateway’s applicable terms.
• Prices and inclusions may change for future enrolments; confirmed paid periods are handled according to our Refund & Cancellation Policy.

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

    private static function contactBody(string $brand, string $website, string $email, string $phone, string $updated): string
    {
        return <<<TEXT
Last updated: {$updated}

We would love to hear from you. Whether you are a parent, student, or school partner, the {$brand} team can help with admissions, programme questions, account support, and payment issues.

Contact details
• Email: {$email}
• Phone / WhatsApp: {$phone}
• Website: {$website}

What to include in your message
• Your name and role (parent/guardian or student)
• Student name and class (6–12)
• Registered email or phone used on the platform
• A short description of your question (admissions, booking, learning access, payment/refund, or technical issue)
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
