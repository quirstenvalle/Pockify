<?php

namespace App\Services;

use App\Mail\VerificationCodeMail;
use App\Models\EmailVerificationCode;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class OtpService
{
    public function issueAndSend(User $user): ?string
    {
        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $ttl = (int) config('pockify.otp_ttl_minutes', 10);

        EmailVerificationCode::updateOrCreate(
            ['email' => $user->email],
            [
                'code_hash' => Hash::make($code),
                'expires_at' => now()->addMinutes($ttl),
                'attempts' => 0,
                'last_sent_at' => now(),
            ]
        );

        Mail::to($user->email)->send(
            new VerificationCodeMail($user->name, $code, $ttl)
        );

        return config('pockify.expose_demo_code') ? $code : null;
    }

    public function verify(User $user, string $code): array
    {
        $row = EmailVerificationCode::where('email', $user->email)->first();
        $maxAttempts = (int) config('pockify.otp_max_attempts', 5);

        if (! $row) {
            return [
                'ok' => false,
                'code' => 'expired_code',
                'message' => 'No active verification code. Please request a new one.',
            ];
        }

        if ($row->attempts >= $maxAttempts) {
            return [
                'ok' => false,
                'code' => 'too_many_attempts',
                'message' => 'Too many incorrect attempts. Request a new verification code.',
            ];
        }

        if ($row->expires_at->isPast()) {
            return [
                'ok' => false,
                'code' => 'expired_code',
                'message' => 'This verification code has expired. Request a new one.',
            ];
        }

        if (! Hash::check($code, $row->code_hash)) {
            $row->increment('attempts');
            $remaining = $maxAttempts - $row->fresh()->attempts;

            if ($remaining <= 0) {
                return [
                    'ok' => false,
                    'code' => 'too_many_attempts',
                    'message' => 'Too many incorrect attempts. Request a new verification code.',
                ];
            }

            return [
                'ok' => false,
                'code' => 'invalid_code',
                'message' => "Incorrect verification code. {$remaining} attempt".($remaining === 1 ? '' : 's').' left.',
            ];
        }

        $row->delete();

        return ['ok' => true];
    }

    public function resendCooldownRemaining(User $user): int
    {
        $row = EmailVerificationCode::where('email', $user->email)->first();
        if (! $row?->last_sent_at) {
            return 0;
        }

        $wait = (int) config('pockify.otp_resend_seconds', 30);
        $elapsed = $row->last_sent_at->diffInSeconds(now());

        return max(0, $wait - $elapsed);
    }

    public function remainingSeconds(string $email): int
    {
        $row = EmailVerificationCode::where('email', strtolower($email))->first();
        if (! $row) {
            return 0;
        }

        return max(0, now()->diffInSeconds($row->expires_at, false));
    }
}
