Hello {{ $recipientName }},

An administrator has created your {{ $roleLabel }} account on {{ $appName }}.

Portal: {{ $loginUrl }}
Email: {{ $email }}
@if (! empty($studentCode))
Student ID: {{ $studentCode }}
@endif
Temporary password: {{ $temporaryPassword }}

For your security, please sign in and change this password as soon as possible (Profile → Change password), or use Forgot password on the sign-in page.

If you did not expect this email, ignore it and contact your school administrator. Do not forward this message.

— {{ $appName }}
