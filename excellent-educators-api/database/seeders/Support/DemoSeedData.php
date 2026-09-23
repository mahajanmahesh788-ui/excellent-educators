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
                'name' => 'Aisha Rahman',
                'email' => 'aisha.rahman@excellenteducators.test',
                'password' => self::TEACHER_PASSWORD,
                'gender' => 'female',
                'employee_code' => 'MT-DEMO-001',
                'phone' => '+919876543201',
                'whatsapp_number' => '+919876543201',
                'address' => '12 Lake View Road, Bengaluru',
                'photo_url' => 'https://i.pravatar.cc/300?u=aisha.rahman',
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
                'name' => 'Rohan Mehta',
                'email' => 'rohan.mehta@excellenteducators.test',
                'password' => self::TEACHER_PASSWORD,
                'gender' => 'male',
                'employee_code' => 'MT-DEMO-002',
                'phone' => '+919876543202',
                'whatsapp_number' => '+919876543202',
                'address' => '88 Marine Drive, Mumbai',
                'photo_url' => rtrim((string) config('app.url'), '/').'/media/teachers/rohan-mehta.jpg',
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
                'name' => 'Priya Nair',
                'email' => 'priya.nair@excellenteducators.test',
                'password' => self::TEACHER_PASSWORD,
                'gender' => 'female',
                'employee_code' => 'MT-DEMO-003',
                'phone' => '+919876543203',
                'whatsapp_number' => '+919876543203',
                'address' => '5 Palm Grove, Kochi',
                'photo_url' => 'https://i.pravatar.cc/300?u=priya.nair',
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
}
