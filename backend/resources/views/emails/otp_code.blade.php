<!DOCTYPE html>
<html dir="{{ app()->getLocale() === 'ar' ? 'rtl' : 'ltr' }}" lang="{{ app()->getLocale() }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('otp-email-subject') }}</title>
</head>
<body style="margin:0;padding:0;background:#f3f1fb;font-family:Arial,Helvetica,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f3f1fb;padding:32px 0;">
        <tr>
            <td align="center">
                <table role="presentation" width="440" cellpadding="0" cellspacing="0"
                       style="background:#ffffff;border-radius:16px;overflow:hidden;max-width:92%;">
                    <tr>
                        <td style="background:linear-gradient(135deg,#7E3E97,#463394);padding:28px 32px;">
                            <h1 style="margin:0;color:#ffffff;font-size:20px;">{{ config('app.name') }}</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:32px;color:#2b2b3a;">
                            <p style="margin:0 0 8px;font-size:16px;font-weight:bold;">{{ __('otp-email-greeting') }}</p>
                            <p style="margin:0 0 24px;font-size:14px;color:#555;line-height:1.6;">{{ __('otp-email-line') }}</p>
                            <div style="text-align:center;margin:0 0 24px;">
                                <span style="display:inline-block;background:#f3f1fb;border:1px solid #ddd6f3;border-radius:12px;
                                             padding:16px 28px;font-size:32px;font-weight:bold;letter-spacing:8px;color:#463394;">
                                    {{ $code }}
                                </span>
                            </div>
                            <p style="margin:0;font-size:12px;color:#999;line-height:1.6;">{{ __('otp-email-ignore') }}</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
