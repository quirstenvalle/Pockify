<?php

return [
    'otp_ttl_minutes' => (int) env('POCKIFY_OTP_TTL_MINUTES', 10),
    'otp_max_attempts' => (int) env('POCKIFY_OTP_MAX_ATTEMPTS', 5),
    'otp_resend_seconds' => (int) env('POCKIFY_OTP_RESEND_SECONDS', 30),
    'expose_demo_code' => filter_var(env('POCKIFY_EXPOSE_DEMO_CODE', true), FILTER_VALIDATE_BOOL),
];
