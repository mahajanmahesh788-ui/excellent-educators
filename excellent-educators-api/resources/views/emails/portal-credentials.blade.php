<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Your {{ $appName }} account</title>
</head>
<body style="margin:0;padding:0;background:#f4f6f8;font-family:Georgia,'Times New Roman',serif;color:#1a2332;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f6f8;padding:32px 16px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background:#ffffff;border:1px solid #e5e9ef;">
                <tr>
                    <td style="padding:28px 28px 12px;background:#0f2744;color:#ffffff;">
                        <p style="margin:0;font-size:13px;letter-spacing:0.08em;text-transform:uppercase;opacity:0.85;">{{ $appName }}</p>
                        <h1 style="margin:10px 0 0;font-size:24px;font-weight:normal;line-height:1.3;">Your account is ready</h1>
                    </td>
                </tr>
                <tr>
                    <td style="padding:28px;">
                        <p style="margin:0 0 16px;font-size:16px;line-height:1.55;">Hello {{ $recipientName }},</p>
                        <p style="margin:0 0 16px;font-size:15px;line-height:1.55;color:#334155;">
                            An administrator has created your <strong>{{ $roleLabel }}</strong> account on {{ $appName }}.
                            Use the details below to sign in for the first time.
                        </p>

                        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:20px 0;background:#f8fafc;border:1px solid #e2e8f0;">
                            <tr>
                                <td style="padding:16px 18px;font-size:14px;line-height:1.7;color:#1e293b;">
                                    <div><strong>Portal</strong><br><a href="{{ $loginUrl }}" style="color:#0f2744;">{{ $loginUrl }}</a></div>
                                    <div style="margin-top:12px;"><strong>Email</strong><br>{{ $email }}</div>
                                    @if (! empty($studentCode))
                                        <div style="margin-top:12px;"><strong>Student ID</strong><br>{{ $studentCode }}</div>
                                    @endif
                                    <div style="margin-top:12px;"><strong>Temporary password</strong><br><span style="font-family:Consolas,Monaco,monospace;font-size:15px;">{{ $temporaryPassword }}</span></div>
                                </td>
                            </tr>
                        </table>

                        <p style="margin:0 0 12px;font-size:15px;line-height:1.55;color:#334155;">
                            For your security, please sign in and <strong>change this password</strong> as soon as possible
                            (Profile → Change password), or use Forgot password on the sign-in page if you prefer a reset link.
                        </p>
                        <p style="margin:0 0 24px;">
                            <a href="{{ $loginUrl }}" style="display:inline-block;background:#0f2744;color:#ffffff;text-decoration:none;padding:12px 20px;font-size:14px;">
                                Go to portal &amp; sign in
                            </a>
                        </p>
                        <p style="margin:0;font-size:13px;line-height:1.5;color:#64748b;">
                            If you did not expect this email, ignore it and contact your school administrator.
                            Do not forward this message — it contains a temporary password.
                        </p>
                    </td>
                </tr>
                <tr>
                    <td style="padding:16px 28px;border-top:1px solid #e5e9ef;font-size:12px;color:#94a3b8;">
                        {{ $appName }} · Account access
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
