<?php

namespace Database\Seeders\Support;

/**
 * Static demo payloads for local/testing seeders only.
 * Keep application code free of this content — edit here when refresh data changes.
 */
abstract class DemoSeedData
{
    public const TEACHER_PASSWORD = 'TeacherPass1!';

    /**
     * @return list<array<string, mixed>>
     */
    public static function teachers(): array
    {
        return [
            [
                'name' => 'Teacher 1',
                'email' => 'teacher1@yopmail.com',
                'password' => self::TEACHER_PASSWORD,
                'gender' => 'female',
                'employee_code' => 'MT-DEMO-001',
                'phone' => '+919876543201',
                'whatsapp_number' => '+919876543201',
                'address' => '12 Lake View Road, Bengaluru',
                'photo_url' => 'https://i.pravatar.cc/300?u=teacher1',
                'professional_title' => 'STEM Career Mentor',
                'bio' => 'Helps students connect classroom learning with real engineering and science paths.',
                'experience_summary' => '12 years mentoring STEM aspirants',
                'guidance_areas' => ['STEM careers', 'College applications', 'Problem solving'],
                'mentoring_approach' => ['1:1 coaching', 'Project walkthroughs', 'Weekly check-ins'],
                'education' => [
                    ['degree' => 'M.Tech Computer Science', 'institution' => 'IISc Bangalore', 'year' => '2012'],
                    ['degree' => 'B.E. Electronics', 'institution' => 'VTU', 'year' => '2010'],
                ],
                'certifications' => [
                    ['name' => 'Career Coaching Certificate', 'organization' => 'ICF', 'year' => '2019'],
                ],
                'experience' => [
                    ['organization' => 'BrightPath Academy', 'role' => 'Lead Mentor', 'duration' => '6 years'],
                    ['organization' => 'TechSpark Labs', 'role' => 'Program Coach', 'duration' => '4 years'],
                ],
            ],
            [
                'name' => 'Teacher 2',
                'email' => 'teacher2@yopmail.com',
                'password' => self::TEACHER_PASSWORD,
                'gender' => 'male',
                'employee_code' => 'MT-DEMO-002',
                'phone' => '+919876543202',
                'whatsapp_number' => '+919876543202',
                'address' => '88 Marine Drive, Mumbai',
                'photo_url' => 'https://i.pravatar.cc/300?u=teacher2',
                'professional_title' => 'Leadership & Communication Mentor',
                'bio' => 'Focuses on confidence, teamwork, and clear communication for school leaders.',
                'experience_summary' => '9 years in youth leadership programs',
                'guidance_areas' => ['Leadership', 'Public speaking', 'Teamwork'],
                'mentoring_approach' => ['Group workshops', 'Role-play practice', 'Reflection journals'],
                'education' => [
                    ['degree' => 'MBA', 'institution' => 'NMIMS Mumbai', 'year' => '2015'],
                    ['degree' => 'B.Com', 'institution' => 'University of Mumbai', 'year' => '2013'],
                ],
                'certifications' => [
                    ['name' => 'Facilitation Skills', 'organization' => 'British Council', 'year' => '2021'],
                ],
                'experience' => [
                    ['organization' => 'YouthLead India', 'role' => 'Program Director', 'duration' => '5 years'],
                    ['organization' => 'SpeakUp Studio', 'role' => 'Communication Coach', 'duration' => '3 years'],
                ],
            ],
            [
                'name' => 'Teacher 3',
                'email' => 'teacher3@yopmail.com',
                'password' => self::TEACHER_PASSWORD,
                'gender' => 'female',
                'employee_code' => 'MT-DEMO-003',
                'phone' => '+919876543203',
                'whatsapp_number' => '+919876543203',
                'address' => '5 Palm Grove, Kochi',
                'photo_url' => 'https://i.pravatar.cc/300?u=teacher3',
                'professional_title' => 'Creativity & Future Pathways Mentor',
                'bio' => 'Guides students exploring design, arts, and interdisciplinary careers.',
                'experience_summary' => '10 years in creative education',
                'guidance_areas' => ['Creativity', 'Design thinking', 'Future aspirations'],
                'mentoring_approach' => ['Portfolio reviews', 'Design sprints', 'Storytelling sessions'],
                'education' => [
                    ['degree' => 'M.Des Interaction Design', 'institution' => 'NID Ahmedabad', 'year' => '2014'],
                    ['degree' => 'B.Des', 'institution' => 'Srishti Institute', 'year' => '2011'],
                ],
                'certifications' => [
                    ['name' => 'Design Thinking Facilitator', 'organization' => 'IDEO U', 'year' => '2020'],
                ],
                'experience' => [
                    ['organization' => 'CreateSpace Studio', 'role' => 'Mentor Lead', 'duration' => '7 years'],
                    ['organization' => 'FutureCraft Labs', 'role' => 'Workshop Facilitator', 'duration' => '3 years'],
                ],
            ],
        ];
    }

    /**
     * Level 1 weekly learning journey (weeks 1–4).
     *
     * @return list<array{week_number: int, video_url: string, questions: list<array<string, mixed>>}>
     */
    public static function levelOneWeeklyLearnings(): array
    {
        return [
            [
                'week_number' => 1,
                'video_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                'video_title' => 'Week 1 · Thinking Foundations',
                'questions' => [
                    [
                        'question_text' => 'You are given a task you have never done before. What do you naturally do first?',
                        'options' => [
                            [
                                'option_text' => 'Break it into smaller parts and understand it.',
                                'dimension_codes' => ['TW', 'CR'],
                            ],
                            [
                                'option_text' => 'Think of different possible solutions.',
                                'dimension_codes' => ['L', 'CM'],
                            ],
                            [
                                'option_text' => 'Discuss it with someone and collect ideas.',
                                'dimension_codes' => ['TW', 'CF'],
                            ],
                            [
                                'option_text' => 'Try it directly and learn as you go.',
                                'dimension_codes' => ['P', 'I'],
                            ],
                        ],
                    ],
                    [
                        'question_text' => 'When a group project is stuck, what is your usual contribution?',
                        'options' => [
                            [
                                'option_text' => 'Organize roles and keep everyone on track.',
                                'dimension_codes' => ['L', 'DM'],
                            ],
                            [
                                'option_text' => 'Share a creative idea to unblock the team.',
                                'dimension_codes' => ['CR', 'CU'],
                            ],
                            [
                                'option_text' => 'Listen carefully and help people feel heard.',
                                'dimension_codes' => ['CM', 'TW'],
                            ],
                            [
                                'option_text' => 'Research options and suggest a clear next step.',
                                'dimension_codes' => ['P', 'FA'],
                            ],
                        ],
                    ],
                ],
            ],
            [
                'week_number' => 2,
                'video_url' => 'https://www.youtube.com/watch?v=jNQXAC9IVRw',
                'video_title' => 'Week 2 · Creative Problem Solving',
                'questions' => [
                    [
                        'question_text' => 'Which kind of challenge energizes you the most?',
                        'options' => [
                            [
                                'option_text' => 'Solving a tough logic or technical puzzle.',
                                'dimension_codes' => ['CR', 'P'],
                            ],
                            [
                                'option_text' => 'Leading people toward a shared goal.',
                                'dimension_codes' => ['L', 'CM'],
                            ],
                            [
                                'option_text' => 'Exploring something completely new.',
                                'dimension_codes' => ['CU', 'I'],
                            ],
                            [
                                'option_text' => 'Helping a teammate grow through support.',
                                'dimension_codes' => ['TW', 'CF'],
                            ],
                        ],
                    ],
                    [
                        'question_text' => 'How do you prefer to make an important decision?',
                        'options' => [
                            [
                                'option_text' => 'List pros and cons, then choose calmly.',
                                'dimension_codes' => ['DM', 'P'],
                            ],
                            [
                                'option_text' => 'Ask mentors and friends for perspectives.',
                                'dimension_codes' => ['CM', 'TW'],
                            ],
                            [
                                'option_text' => 'Trust my instincts and adjust later.',
                                'dimension_codes' => ['CF', 'I'],
                            ],
                            [
                                'option_text' => 'Imagine future outcomes and pick the best path.',
                                'dimension_codes' => ['FA', 'CR'],
                            ],
                        ],
                    ],
                ],
            ],
            [
                'week_number' => 3,
                'video_url' => 'https://www.youtube.com/watch?v=9bZkp7q19f0',
                'video_title' => 'Week 3 · Communication Focus',
                'questions' => [
                    [
                        'question_text' => 'In a classroom discussion, you are most likely to…',
                        'options' => [
                            [
                                'option_text' => 'Ask curious questions that open new angles.',
                                'dimension_codes' => ['CU', 'CM'],
                            ],
                            [
                                'option_text' => 'Summarize ideas so the group stays aligned.',
                                'dimension_codes' => ['L', 'TW'],
                            ],
                            [
                                'option_text' => 'Offer a creative example or story.',
                                'dimension_codes' => ['CR', 'I'],
                            ],
                            [
                                'option_text' => 'Stay quiet first, then share a careful view.',
                                'dimension_codes' => ['P', 'CF'],
                            ],
                        ],
                    ],
                    [
                        'question_text' => 'What does “success” mean to you right now?',
                        'options' => [
                            [
                                'option_text' => 'Growing skills that match my future goals.',
                                'dimension_codes' => ['FA', 'P'],
                            ],
                            [
                                'option_text' => 'Being someone others can rely on.',
                                'dimension_codes' => ['TW', 'L'],
                            ],
                            [
                                'option_text' => 'Expressing myself in original ways.',
                                'dimension_codes' => ['CR', 'I'],
                            ],
                            [
                                'option_text' => 'Feeling confident speaking up for myself.',
                                'dimension_codes' => ['CF', 'CM'],
                            ],
                        ],
                    ],
                ],
            ],
            [
                'week_number' => 4,
                'video_url' => 'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
                'video_title' => 'Week 4 · Collaboration Habits',
                'questions' => [
                    [
                        'question_text' => 'A friend asks for help preparing for an interview. You…',
                        'options' => [
                            [
                                'option_text' => 'Run a mock interview and give clear feedback.',
                                'dimension_codes' => ['CM', 'L'],
                            ],
                            [
                                'option_text' => 'Brainstorm unique answers together.',
                                'dimension_codes' => ['CR', 'TW'],
                            ],
                            [
                                'option_text' => 'Share resources and let them practice alone.',
                                'dimension_codes' => ['P', 'DM'],
                            ],
                            [
                                'option_text' => 'Encourage them until they feel ready.',
                                'dimension_codes' => ['CF', 'I'],
                            ],
                        ],
                    ],
                    [
                        'question_text' => 'Looking ahead five years, what excites you most?',
                        'options' => [
                            [
                                'option_text' => 'Building expertise in a field I care about.',
                                'dimension_codes' => ['FA', 'P'],
                            ],
                            [
                                'option_text' => 'Leading a team that creates impact.',
                                'dimension_codes' => ['L', 'TW'],
                            ],
                            [
                                'option_text' => 'Inventing or designing new things.',
                                'dimension_codes' => ['CR', 'CU'],
                            ],
                            [
                                'option_text' => 'Connecting with people across many paths.',
                                'dimension_codes' => ['CM', 'I'],
                            ],
                        ],
                    ],
                ],
            ],
        ];
    }

    public const STUDENT_PASSWORD = 'StudentPass1!';

    /**
     * Primary / legacy single-journey helper (student1).
     *
     * @return array<string, mixed>
     */
    public static function studentJourney(): array
    {
        return self::studentJourneys()[0];
    }

    /**
     * Demo students covering the main product test cases.
     * Password for all: {@see self::STUDENT_PASSWORD}
     *
     * Cases:
     * 1. student1 — full ~4-month healthy journey
     * 2. student2 — current week assignment still pending
     * 3. student3 — missed introduction (rebooking available)
     * 4. student4 — missed master class (rebooking available)
     * 5. student5 — aptitude not submitted yet
     * 6. student6 — introduction call scheduled upcoming
     * 7. student7 — payment overdue
     * 8. student8 — intro completed, waiting to book first master class
     * 9. student9 — fresh enrollee (aptitude pending, no bookings)
     *
     * @return list<array<string, mixed>>
     */
    public static function studentJourneys(): array
    {
        $teacher = 'teacher1@yopmail.com';
        $basePayment = static fn (string $start, array $followUps = []): array => [
            'payment_type' => 'partial',
            'total_amount' => 12000,
            'initial_amount' => 3000,
            'due_day' => 20,
            'preferred_mode' => 'offline',
            'start_date' => $start,
            'payment_date' => $start,
            'notes' => 'Demo enrolment payment',
            'follow_up_payments' => $followUps,
        ];

        return [
            [
                'key' => 'complete_journey',
                'label' => 'Full healthy journey',
                'student' => [
                    'name' => 'Student 1',
                    'email' => 'student1@yopmail.com',
                    'password' => self::STUDENT_PASSWORD,
                    'gender' => 'female',
                    'class_grade' => 8,
                    'phone' => '+919876501001',
                    'whatsapp_number' => '+919876501001',
                    'address' => '42 Green Park, New Delhi',
                    'guardian_name' => 'Parent One',
                    'guardian_phone' => '+919876501000',
                    'created_at' => '2026-05-28 10:15:00',
                ],
                'master_teacher_email' => $teacher,
                'journey_started_at' => '2026-05-28 00:00:00',
                'master_teacher_assigned_at' => '2026-05-28 11:00:00',
                'aptitude_submitted_at' => '2026-05-29 16:30:00',
                'aptitude_option_index' => 0,
                'payment' => $basePayment('2026-05-28', [
                    ['amount' => 2250, 'payment_date' => '2026-06-20', 'notes' => 'June installment'],
                    ['amount' => 2250, 'payment_date' => '2026-07-20', 'notes' => 'July installment'],
                    ['amount' => 2250, 'payment_date' => '2026-08-20', 'notes' => 'August installment'],
                    ['amount' => 2250, 'payment_date' => '2026-09-20', 'notes' => 'September installment'],
                ]),
                'weekly_attempts' => [
                    ['week_number' => 1, 'submitted_at' => '2026-06-04 18:00:00', 'option_index' => 0],
                    ['week_number' => 2, 'submitted_at' => '2026-06-11 18:00:00', 'option_index' => 1],
                    ['week_number' => 3, 'submitted_at' => '2026-06-18 18:00:00', 'option_index' => 0],
                    ['week_number' => 4, 'submitted_at' => '2026-06-25 18:00:00', 'option_index' => 2],
                ],
                'bookings' => [
                    [
                        'type' => 'introduction_call',
                        'date' => '2026-05-30',
                        'start' => '10:00',
                        'status' => 'completed',
                        'attendance' => 'attended',
                    ],
                    [
                        'type' => 'master_class',
                        'date' => '2026-06-15',
                        'start' => '10:00',
                        'status' => 'completed',
                        'attendance' => 'attended',
                        'rate' => true,
                        'feedback' => [
                            'positive_points' => 'Curious and engages well in discussion.',
                            'areas_for_improvement' => 'Can prepare one example before class.',
                            'discussed_in_class' => 'STEM interests and weekly learning habit.',
                            'dimension_rating' => 7,
                        ],
                    ],
                    [
                        'type' => 'master_class',
                        'date' => '2026-07-18',
                        'start' => '11:00',
                        'status' => 'completed',
                        'attendance' => 'attended',
                        'rate' => true,
                        'feedback' => [
                            'positive_points' => 'Shows steady growth in teamwork.',
                            'areas_for_improvement' => 'Speak a bit louder in group tasks.',
                            'discussed_in_class' => 'Communication confidence.',
                            'dimension_rating' => 8,
                        ],
                    ],
                    [
                        'type' => 'master_class',
                        'date' => '2026-08-12',
                        'start' => '10:30',
                        'status' => 'completed',
                        'attendance' => 'attended',
                        'rate' => true,
                        'feedback' => [
                            'positive_points' => 'Takes ownership of weekly assignments.',
                            'areas_for_improvement' => 'Try one stretch challenge each week.',
                            'discussed_in_class' => 'Creative problem solving.',
                            'dimension_rating' => 8,
                        ],
                    ],
                    [
                        'type' => 'master_class',
                        'date' => '2026-09-20',
                        'start' => '10:00',
                        'status' => 'completed',
                        'attendance' => 'attended',
                        'rate' => true,
                        'feedback' => [
                            'positive_points' => 'Reflects thoughtfully on mentor feedback.',
                            'areas_for_improvement' => 'Keep building leadership moments.',
                            'discussed_in_class' => 'Four-month progress review.',
                            'dimension_rating' => 9,
                        ],
                    ],
                ],
            ],
            [
                'key' => 'pending_assignment',
                'label' => 'Pending current-week assignment',
                'student' => [
                    'name' => 'Student 2',
                    'email' => 'student2@yopmail.com',
                    'password' => self::STUDENT_PASSWORD,
                    'gender' => 'male',
                    'class_grade' => 7,
                    'phone' => '+919876501002',
                    'whatsapp_number' => '+919876501002',
                    'address' => '18 Lake Road, Pune',
                    'guardian_name' => 'Parent Two',
                    'guardian_phone' => '+919876501012',
                    // Started ~3 weeks ago → current week is 4; weeks 1–3 done, week 4 pending.
                    'created_at' => '2026-09-09 09:00:00',
                ],
                'master_teacher_email' => $teacher,
                'journey_started_at' => '2026-09-09 00:00:00',
                'master_teacher_assigned_at' => '2026-09-09 10:00:00',
                'aptitude_submitted_at' => '2026-09-09 15:00:00',
                'aptitude_option_index' => 1,
                'payment' => [
                    'payment_type' => 'full',
                    'total_amount' => 12000,
                    'initial_amount' => 12000,
                    'due_day' => 20,
                    'preferred_mode' => 'offline',
                    'start_date' => '2026-09-09',
                    'payment_date' => '2026-09-09',
                    'notes' => 'Demo full payment — focus is pending assignment',
                    'follow_up_payments' => [],
                ],
                'weekly_attempts' => [
                    ['week_number' => 1, 'submitted_at' => '2026-09-12 18:00:00', 'option_index' => 0],
                    ['week_number' => 2, 'submitted_at' => '2026-09-19 18:00:00', 'option_index' => 1],
                    ['week_number' => 3, 'submitted_at' => '2026-09-26 18:00:00', 'option_index' => 0],
                    // week 4 intentionally omitted → pending assignment
                ],
                'bookings' => [
                    [
                        'type' => 'introduction_call',
                        'date' => '2026-09-10',
                        'start' => '10:00',
                        'status' => 'completed',
                        'attendance' => 'attended',
                    ],
                ],
            ],
            [
                'key' => 'missed_introduction',
                'label' => 'Missed introduction call (rebooking available)',
                'student' => [
                    'name' => 'Student 3',
                    'email' => 'student3@yopmail.com',
                    'password' => self::STUDENT_PASSWORD,
                    'gender' => 'female',
                    'class_grade' => 9,
                    'phone' => '+919876501003',
                    'whatsapp_number' => '+919876501003',
                    'address' => '7 Ring Road, Jaipur',
                    'guardian_name' => 'Parent Three',
                    'guardian_phone' => '+919876501013',
                    'created_at' => '2026-09-22 10:00:00',
                ],
                'master_teacher_email' => $teacher,
                'journey_started_at' => '2026-09-22 00:00:00',
                'master_teacher_assigned_at' => '2026-09-22 11:00:00',
                'aptitude_submitted_at' => '2026-09-22 16:00:00',
                'aptitude_option_index' => 0,
                'payment' => $basePayment('2026-09-22'),
                'weekly_attempts' => [],
                'bookings' => [
                    [
                        'type' => 'introduction_call',
                        'date' => '2026-09-25',
                        'start' => '10:00',
                        'status' => 'scheduled',
                        'attendance' => 'student_missed',
                        'rebooking_granted' => true,
                        'attendance_issue' => [
                            'issue_type' => 'student_did_not_join',
                            'decision' => 'student_absent',
                            'message' => 'Student did not join the introduction call.',
                        ],
                    ],
                ],
            ],
            [
                'key' => 'missed_master_class',
                'label' => 'Missed master class (rebooking available)',
                'student' => [
                    'name' => 'Student 4',
                    'email' => 'student4@yopmail.com',
                    'password' => self::STUDENT_PASSWORD,
                    'gender' => 'male',
                    'class_grade' => 8,
                    'phone' => '+919876501004',
                    'whatsapp_number' => '+919876501004',
                    'address' => '55 MG Road, Bengaluru',
                    'guardian_name' => 'Parent Four',
                    'guardian_phone' => '+919876501014',
                    'created_at' => '2026-08-01 10:00:00',
                ],
                'master_teacher_email' => $teacher,
                'journey_started_at' => '2026-08-01 00:00:00',
                'master_teacher_assigned_at' => '2026-08-01 11:00:00',
                'aptitude_submitted_at' => '2026-08-01 17:00:00',
                'aptitude_option_index' => 2,
                'payment' => $basePayment('2026-08-01', [
                    ['amount' => 2250, 'payment_date' => '2026-08-20', 'notes' => 'August installment'],
                ]),
                'weekly_attempts' => [
                    ['week_number' => 1, 'submitted_at' => '2026-08-08 18:00:00', 'option_index' => 0],
                    ['week_number' => 2, 'submitted_at' => '2026-08-15 18:00:00', 'option_index' => 1],
                ],
                'bookings' => [
                    [
                        'type' => 'introduction_call',
                        'date' => '2026-08-03',
                        'start' => '10:00',
                        'status' => 'completed',
                        'attendance' => 'attended',
                    ],
                    [
                        'type' => 'master_class',
                        'date' => '2026-09-18',
                        'start' => '11:00',
                        'status' => 'scheduled',
                        'attendance' => 'student_missed',
                        'rebooking_granted' => true,
                        'attendance_issue' => [
                            'issue_type' => 'student_did_not_join',
                            'decision' => 'student_absent',
                            'message' => 'Student missed the September master class.',
                        ],
                    ],
                ],
            ],
            [
                'key' => 'aptitude_pending',
                'label' => 'Aptitude assessment not submitted',
                'student' => [
                    'name' => 'Student 5',
                    'email' => 'student5@yopmail.com',
                    'password' => self::STUDENT_PASSWORD,
                    'gender' => 'female',
                    'class_grade' => 6,
                    'phone' => '+919876501005',
                    'whatsapp_number' => '+919876501005',
                    'address' => '12 Sector 18, Noida',
                    'guardian_name' => 'Parent Five',
                    'guardian_phone' => '+919876501015',
                    'created_at' => '2026-09-28 09:30:00',
                ],
                'master_teacher_email' => $teacher,
                'journey_started_at' => '2026-09-28 00:00:00',
                'master_teacher_assigned_at' => '2026-09-28 10:00:00',
                'skip_aptitude' => true,
                'payment' => $basePayment('2026-09-28'),
                'weekly_attempts' => [],
                'bookings' => [],
            ],
            [
                'key' => 'intro_scheduled',
                'label' => 'Introduction call scheduled (upcoming)',
                'student' => [
                    'name' => 'Student 6',
                    'email' => 'student6@yopmail.com',
                    'password' => self::STUDENT_PASSWORD,
                    'gender' => 'male',
                    'class_grade' => 10,
                    'phone' => '+919876501006',
                    'whatsapp_number' => '+919876501006',
                    'address' => '90 Anna Salai, Chennai',
                    'guardian_name' => 'Parent Six',
                    'guardian_phone' => '+919876501016',
                    'created_at' => '2026-09-27 11:00:00',
                ],
                'master_teacher_email' => $teacher,
                'journey_started_at' => '2026-09-27 00:00:00',
                'master_teacher_assigned_at' => '2026-09-27 12:00:00',
                'aptitude_submitted_at' => '2026-09-27 18:00:00',
                'aptitude_option_index' => 0,
                'payment' => $basePayment('2026-09-27'),
                'weekly_attempts' => [],
                'bookings' => [
                    [
                        'type' => 'introduction_call',
                        'date' => '2026-10-03',
                        'start' => '10:00',
                        'status' => 'scheduled',
                        'attendance' => 'none',
                    ],
                ],
            ],
            [
                'key' => 'payment_overdue',
                'label' => 'Payment overdue',
                'student' => [
                    'name' => 'Student 7',
                    'email' => 'student7@yopmail.com',
                    'password' => self::STUDENT_PASSWORD,
                    'gender' => 'female',
                    'class_grade' => 8,
                    'phone' => '+919876501007',
                    'whatsapp_number' => '+919876501007',
                    'address' => '3 Park Street, Kolkata',
                    'guardian_name' => 'Parent Seven',
                    'guardian_phone' => '+919876501017',
                    'created_at' => '2026-06-15 10:00:00',
                ],
                'master_teacher_email' => $teacher,
                'journey_started_at' => '2026-06-15 00:00:00',
                'master_teacher_assigned_at' => '2026-06-15 11:00:00',
                'aptitude_submitted_at' => '2026-06-16 14:00:00',
                'aptitude_option_index' => 1,
                // Only enrolment paid — installments never recorded → overdue by Sep.
                'payment' => $basePayment('2026-06-15'),
                'weekly_attempts' => [
                    ['week_number' => 1, 'submitted_at' => '2026-06-22 18:00:00', 'option_index' => 0],
                ],
                'bookings' => [
                    [
                        'type' => 'introduction_call',
                        'date' => '2026-06-18',
                        'start' => '10:00',
                        'status' => 'completed',
                        'attendance' => 'attended',
                    ],
                    [
                        'type' => 'master_class',
                        'date' => '2026-07-10',
                        'start' => '10:00',
                        'status' => 'completed',
                        'attendance' => 'attended',
                        'rate' => true,
                        'feedback' => [
                            'positive_points' => 'Participates when present.',
                            'areas_for_improvement' => 'Keep fee installments on schedule.',
                            'discussed_in_class' => 'Payment follow-up and weekly habit.',
                            'dimension_rating' => 6,
                        ],
                    ],
                ],
            ],
            [
                'key' => 'awaiting_master_class',
                'label' => 'Intro done — ready to book first master class',
                'student' => [
                    'name' => 'Student 8',
                    'email' => 'student8@yopmail.com',
                    'password' => self::STUDENT_PASSWORD,
                    'gender' => 'male',
                    'class_grade' => 7,
                    'phone' => '+919876501008',
                    'whatsapp_number' => '+919876501008',
                    'address' => '21 Civil Lines, Lucknow',
                    'guardian_name' => 'Parent Eight',
                    'guardian_phone' => '+919876501018',
                    // Journey started last month so master class unlocks this month.
                    'created_at' => '2026-08-20 10:00:00',
                ],
                'master_teacher_email' => $teacher,
                'journey_started_at' => '2026-08-20 00:00:00',
                'master_teacher_assigned_at' => '2026-08-20 11:00:00',
                'aptitude_submitted_at' => '2026-08-20 16:00:00',
                'aptitude_option_index' => 0,
                'payment' => $basePayment('2026-08-20', [
                    ['amount' => 2250, 'payment_date' => '2026-09-20', 'notes' => 'September installment'],
                ]),
                'weekly_attempts' => [
                    ['week_number' => 1, 'submitted_at' => '2026-08-27 18:00:00', 'option_index' => 0],
                    ['week_number' => 2, 'submitted_at' => '2026-09-03 18:00:00', 'option_index' => 1],
                    ['week_number' => 3, 'submitted_at' => '2026-09-10 18:00:00', 'option_index' => 0],
                    ['week_number' => 4, 'submitted_at' => '2026-09-17 18:00:00', 'option_index' => 2],
                ],
                'bookings' => [
                    [
                        'type' => 'introduction_call',
                        'date' => '2026-08-22',
                        'start' => '10:00',
                        'status' => 'completed',
                        'attendance' => 'attended',
                    ],
                    // No master class yet — can book first MC.
                ],
            ],
            [
                'key' => 'fresh_enrollee',
                'label' => 'Fresh enrollee — aptitude pending',
                'student' => [
                    'name' => 'Student 9',
                    'email' => 'student9@yopmail.com',
                    'password' => self::STUDENT_PASSWORD,
                    'gender' => 'female',
                    'class_grade' => 6,
                    'phone' => '+919876501009',
                    'whatsapp_number' => '+919876501009',
                    'address' => '14 Station Road, Indore',
                    'guardian_name' => 'Parent Nine',
                    'guardian_phone' => '+919876501019',
                    'created_at' => '2026-10-08 09:00:00',
                ],
                'master_teacher_email' => $teacher,
                'journey_started_at' => '2026-10-08 00:00:00',
                'master_teacher_assigned_at' => '2026-10-08 10:00:00',
                'skip_aptitude' => true,
                'payment' => $basePayment('2026-10-08'),
                'weekly_attempts' => [],
                'bookings' => [],
            ],
        ];
    }

    /**
     * Level 2 weekly learning journey (weeks 1–4).
     *
     * @return list<array{week_number: int, video_url: string, comprehension_paragraph?: string, questions: list<array<string, mixed>>}>
     */
    public static function levelTwoWeeklyLearnings(): array
    {
        return [
            [
                'week_number' => 1,
                'video_url' => 'https://www.youtube.com/watch?v=3JZ_D3ELwOQ',
                'video_title' => 'Week 1 · Thinking Foundations',
                'comprehension_paragraph' => 'At Level 2, students deepen self-awareness by reflecting on how they solve problems with others.',
                'questions' => [
                    [
                        'question_text' => 'When a team goal feels unclear, what do you do first?',
                        'options' => [
                            [
                                'option_text' => 'Clarify the goal and break work into steps.',
                                'dimension_codes' => ['L', 'DM'],
                            ],
                            [
                                'option_text' => 'Ask teammates what they need before deciding.',
                                'dimension_codes' => ['CM', 'TW'],
                            ],
                            [
                                'option_text' => 'Sketch a few creative approaches to try.',
                                'dimension_codes' => ['CR', 'CU'],
                            ],
                            [
                                'option_text' => 'Start a small experiment and learn fast.',
                                'dimension_codes' => ['P', 'I'],
                            ],
                        ],
                    ],
                    [
                        'question_text' => 'Which feedback helps you grow the most?',
                        'options' => [
                            [
                                'option_text' => 'Specific notes on how I communicate.',
                                'dimension_codes' => ['CM', 'CF'],
                            ],
                            [
                                'option_text' => 'Challenge to lead a part of the work.',
                                'dimension_codes' => ['L', 'FA'],
                            ],
                            [
                                'option_text' => 'Ideas that stretch my creativity.',
                                'dimension_codes' => ['CR', 'CU'],
                            ],
                            [
                                'option_text' => 'A clear checklist of next skills to practice.',
                                'dimension_codes' => ['P', 'DM'],
                            ],
                        ],
                    ],
                ],
            ],
            [
                'week_number' => 2,
                'video_url' => 'https://www.youtube.com/watch?v=2Vv-BfVoq4g',
                'video_title' => 'Week 2 · Creative Problem Solving',
                'questions' => [
                    [
                        'question_text' => 'A classmate disagrees with your plan. You…',
                        'options' => [
                            [
                                'option_text' => 'Listen fully, then find common ground.',
                                'dimension_codes' => ['CM', 'TW'],
                            ],
                            [
                                'option_text' => 'Explain your reasoning with calm confidence.',
                                'dimension_codes' => ['CF', 'L'],
                            ],
                            [
                                'option_text' => 'Invite a third idea that blends both views.',
                                'dimension_codes' => ['CR', 'DM'],
                            ],
                            [
                                'option_text' => 'Gather facts before choosing a path.',
                                'dimension_codes' => ['P', 'CU'],
                            ],
                        ],
                    ],
                    [
                        'question_text' => 'What kind of project feels most meaningful now?',
                        'options' => [
                            [
                                'option_text' => 'One that builds a skill for my future path.',
                                'dimension_codes' => ['FA', 'P'],
                            ],
                            [
                                'option_text' => 'One where I guide peers toward a goal.',
                                'dimension_codes' => ['L', 'TW'],
                            ],
                            [
                                'option_text' => 'One that lets me invent something new.',
                                'dimension_codes' => ['CR', 'I'],
                            ],
                            [
                                'option_text' => 'One that needs clear, careful decisions.',
                                'dimension_codes' => ['DM', 'CF'],
                            ],
                        ],
                    ],
                ],
            ],
            [
                'week_number' => 3,
                'video_url' => 'https://www.youtube.com/watch?v=lTRiuFIWV54',
                'video_title' => 'Week 3 · Communication Focus',
                'questions' => [
                    [
                        'question_text' => 'How do you usually prepare for a tough class?',
                        'options' => [
                            [
                                'option_text' => 'Plan questions and practice answers aloud.',
                                'dimension_codes' => ['CM', 'CF'],
                            ],
                            [
                                'option_text' => 'Map topics and prioritize what matters.',
                                'dimension_codes' => ['DM', 'P'],
                            ],
                            [
                                'option_text' => 'Explore related examples out of curiosity.',
                                'dimension_codes' => ['CU', 'I'],
                            ],
                            [
                                'option_text' => 'Study with a peer and share roles.',
                                'dimension_codes' => ['TW', 'L'],
                            ],
                        ],
                    ],
                    [
                        'question_text' => 'When progress feels slow, you tend to…',
                        'options' => [
                            [
                                'option_text' => 'Adjust the plan and keep moving.',
                                'dimension_codes' => ['DM', 'P'],
                            ],
                            [
                                'option_text' => 'Ask for support and keep morale up.',
                                'dimension_codes' => ['TW', 'CF'],
                            ],
                            [
                                'option_text' => 'Try a fresh creative angle.',
                                'dimension_codes' => ['CR', 'CU'],
                            ],
                            [
                                'option_text' => 'Reconnect with why the goal matters.',
                                'dimension_codes' => ['FA', 'I'],
                            ],
                        ],
                    ],
                ],
            ],
            [
                'week_number' => 4,
                'video_url' => 'https://www.youtube.com/watch?v=fJ9rUzIMcZQ',
                'video_title' => 'Week 4 · Collaboration Habits',
                'questions' => [
                    [
                        'question_text' => 'What does strong teamwork look like to you?',
                        'options' => [
                            [
                                'option_text' => 'Clear roles and shared ownership.',
                                'dimension_codes' => ['TW', 'L'],
                            ],
                            [
                                'option_text' => 'Honest talk and careful listening.',
                                'dimension_codes' => ['CM', 'CF'],
                            ],
                            [
                                'option_text' => 'Room for bold, original ideas.',
                                'dimension_codes' => ['CR', 'I'],
                            ],
                            [
                                'option_text' => 'Decisions backed by evidence.',
                                'dimension_codes' => ['DM', 'P'],
                            ],
                        ],
                    ],
                    [
                        'question_text' => 'Looking at Level 2 goals, you most want to grow in…',
                        'options' => [
                            [
                                'option_text' => 'Leading with confidence.',
                                'dimension_codes' => ['L', 'CF'],
                            ],
                            [
                                'option_text' => 'Communicating ideas clearly.',
                                'dimension_codes' => ['CM', 'TW'],
                            ],
                            [
                                'option_text' => 'Creative problem solving.',
                                'dimension_codes' => ['CR', 'CU'],
                            ],
                            [
                                'option_text' => 'Planning my next learning steps.',
                                'dimension_codes' => ['FA', 'DM'],
                            ],
                        ],
                    ],
                ],
            ],
        ];
    }

    /**
     * Two aptitude assessments: Level 1 and Level 2.
     *
     * @return list<array{title: string, description: string, level_number: int, questions: list<array<string, mixed>>}>
     */
    public static function aptitudeAssessments(): array
    {
        return [
            [
                'title' => 'Level 1 Aptitude Assessment',
                'description' => 'Baseline strengths check for students starting Level 1.',
                'level_number' => 1,
                'questions' => [
                    [
                        'question_text' => 'Which activity do you enjoy most after school?',
                        'options' => [
                            ['option_text' => 'Solving puzzles or building something', 'dimension_codes' => ['CR', 'P']],
                            ['option_text' => 'Talking through ideas with friends', 'dimension_codes' => ['CM', 'TW']],
                            ['option_text' => 'Organizing a group activity', 'dimension_codes' => ['L', 'DM']],
                            ['option_text' => 'Trying a hobby I have never done', 'dimension_codes' => ['CU', 'I']],
                        ],
                    ],
                    [
                        'question_text' => 'When homework feels hard, what do you do first?',
                        'options' => [
                            ['option_text' => 'Break it into smaller steps', 'dimension_codes' => ['P', 'DM']],
                            ['option_text' => 'Ask a friend or teacher for help', 'dimension_codes' => ['CM', 'TW']],
                            ['option_text' => 'Look for a creative way to understand it', 'dimension_codes' => ['CR', 'CU']],
                            ['option_text' => 'Encourage myself and keep going', 'dimension_codes' => ['CF', 'I']],
                        ],
                    ],
                    [
                        'question_text' => 'In a group project, you usually…',
                        'options' => [
                            ['option_text' => 'Take the lead and assign roles', 'dimension_codes' => ['L', 'DM']],
                            ['option_text' => 'Make sure everyone feels included', 'dimension_codes' => ['TW', 'CM']],
                            ['option_text' => 'Bring new ideas to the table', 'dimension_codes' => ['CR', 'CU']],
                            ['option_text' => 'Research carefully before deciding', 'dimension_codes' => ['P', 'FA']],
                        ],
                    ],
                    [
                        'question_text' => 'What feels most exciting about your future?',
                        'options' => [
                            ['option_text' => 'Learning skills for a career I care about', 'dimension_codes' => ['FA', 'P']],
                            ['option_text' => 'Leading people toward a shared goal', 'dimension_codes' => ['L', 'TW']],
                            ['option_text' => 'Inventing or designing new things', 'dimension_codes' => ['CR', 'I']],
                            ['option_text' => 'Meeting people and sharing stories', 'dimension_codes' => ['CM', 'CF']],
                        ],
                    ],
                ],
            ],
            [
                'title' => 'Level 2 Aptitude Assessment',
                'description' => 'Deeper strengths check for students promoted to Level 2.',
                'level_number' => 2,
                'questions' => [
                    [
                        'question_text' => 'You are asked to improve a school event. Where do you start?',
                        'options' => [
                            ['option_text' => 'Interview people and gather feedback', 'dimension_codes' => ['CM', 'CU']],
                            ['option_text' => 'Map goals, owners, and deadlines', 'dimension_codes' => ['L', 'DM']],
                            ['option_text' => 'Sketch bold new formats to try', 'dimension_codes' => ['CR', 'I']],
                            ['option_text' => 'Study what worked last year carefully', 'dimension_codes' => ['P', 'FA']],
                        ],
                    ],
                    [
                        'question_text' => 'A teammate is stuck and frustrated. You…',
                        'options' => [
                            ['option_text' => 'Listen first, then coach them calmly', 'dimension_codes' => ['CM', 'CF']],
                            ['option_text' => 'Help reorganize the shared plan', 'dimension_codes' => ['L', 'TW']],
                            ['option_text' => 'Offer a fresh creative approach', 'dimension_codes' => ['CR', 'CU']],
                            ['option_text' => 'Break their task into clearer steps', 'dimension_codes' => ['P', 'DM']],
                        ],
                    ],
                    [
                        'question_text' => 'Which decision style fits you best at Level 2?',
                        'options' => [
                            ['option_text' => 'Weigh options with clear criteria', 'dimension_codes' => ['DM', 'P']],
                            ['option_text' => 'Discuss with trusted peers first', 'dimension_codes' => ['TW', 'CM']],
                            ['option_text' => 'Trust instincts, then refine', 'dimension_codes' => ['CF', 'I']],
                            ['option_text' => 'Imagine long-term impact before choosing', 'dimension_codes' => ['FA', 'CR']],
                        ],
                    ],
                    [
                        'question_text' => 'What growth goal matters most to you now?',
                        'options' => [
                            ['option_text' => 'Speak up with more confidence', 'dimension_codes' => ['CF', 'CM']],
                            ['option_text' => 'Lead small teams effectively', 'dimension_codes' => ['L', 'TW']],
                            ['option_text' => 'Solve problems more creatively', 'dimension_codes' => ['CR', 'CU']],
                            ['option_text' => 'Plan learning for my next path', 'dimension_codes' => ['FA', 'DM']],
                        ],
                    ],
                    [
                        'question_text' => 'When exploring a new subject, you prefer to…',
                        'options' => [
                            ['option_text' => 'Ask many questions and dig deeper', 'dimension_codes' => ['CU', 'CM']],
                            ['option_text' => 'Practice until the method feels solid', 'dimension_codes' => ['P', 'CF']],
                            ['option_text' => 'Connect it to a future goal', 'dimension_codes' => ['FA', 'I']],
                            ['option_text' => 'Teach someone else what you learned', 'dimension_codes' => ['L', 'TW']],
                        ],
                    ],
                ],
            ],
        ];
    }
}
