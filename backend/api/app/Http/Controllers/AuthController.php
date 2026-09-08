<?php

namespace App\Http\Controllers;

use App\Mail\VerificationCodeMail;
use App\Models\EmailVerificationCode;
use App\Models\User;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(private readonly OtpService $otp)
    {
    }

    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'currency' => ['nullable', 'string', 'max:40'],
            'employment_status' => ['nullable', 'string', 'max:40'],
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => strtolower($data['email']),
            'password' => Hash::make($data['password']),
            'currency' => $data['currency'] ?? null,
            'employment_status' => $data['employment_status'] ?? null,
            'email_verified_at' => null,
        ]);

        $demoCode = $this->otp->issueAndSend($user);

        return response()->json([
            'ok' => false,
            'requires_verification' => true,
            'message' => 'Account created. Please verify your email to continue.',
            'demo_code' => $demoCode,
            'user' => $this->userPayload($user),
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', strtolower($data['email']))->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Incorrect email or password.'],
            ]);
        }

        if (! $user->hasVerifiedEmail()) {
            $demoCode = $this->otp->issueAndSend($user);

            return response()->json([
                'ok' => false,
                'requires_verification' => true,
                'code' => 'email_unverified',
                'message' => 'Your email is not verified yet. We sent a new verification code.',
                'demo_code' => $demoCode,
                'user' => $this->userPayload($user),
            ], 403);
        }

        $token = $user->createToken('pockify-mobile')->plainTextToken;

        return response()->json([
            'ok' => true,
            'token' => $token,
            'user' => $this->userPayload($user),
        ]);
    }

    public function verifyEmail(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'string', 'size:6'],
        ]);

        $user = User::where('email', strtolower($data['email']))->first();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'code' => 'email_not_found',
                'message' => 'No account found for that email.',
            ], 404);
        }

        if ($user->hasVerifiedEmail()) {
            $token = $user->createToken('pockify-mobile')->plainTextToken;

            return response()->json([
                'ok' => true,
                'token' => $token,
                'user' => $this->userPayload($user),
            ]);
        }

        $result = $this->otp->verify($user, $data['code']);
        if (! $result['ok']) {
            return response()->json([
                'ok' => false,
                'requires_verification' => true,
                'code' => $result['code'],
                'message' => $result['message'],
            ], 422);
        }

        $user->forceFill(['email_verified_at' => now()])->save();
        $token = $user->createToken('pockify-mobile')->plainTextToken;

        return response()->json([
            'ok' => true,
            'token' => $token,
            'user' => $this->userPayload($user),
            'message' => 'Email verified successfully.',
        ]);
    }

    public function resendCode(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $user = User::where('email', strtolower($data['email']))->first();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'code' => 'email_not_found',
                'message' => 'No account found for that email.',
            ], 404);
        }

        if ($user->hasVerifiedEmail()) {
            return response()->json([
                'ok' => true,
                'user' => $this->userPayload($user),
                'message' => 'Email is already verified.',
            ]);
        }

        $cooldown = $this->otp->resendCooldownRemaining($user);
        if ($cooldown > 0) {
            return response()->json([
                'ok' => false,
                'requires_verification' => true,
                'code' => 'resend_cooldown',
                'message' => "Please wait {$cooldown}s before requesting another code.",
            ], 429);
        }

        $demoCode = $this->otp->issueAndSend($user);

        return response()->json([
            'ok' => false,
            'requires_verification' => true,
            'message' => "We've sent a new verification code to your email.",
            'demo_code' => $demoCode,
            'user' => $this->userPayload($user),
        ]);
    }

    public function changeEmail(Request $request)
    {
        $data = $request->validate([
            'current_email' => ['required', 'email'],
            'new_email' => ['required', 'email', 'max:190'],
        ]);

        $current = strtolower($data['current_email']);
        $next = strtolower($data['new_email']);

        $user = User::where('email', $current)->first();
        if (! $user) {
            return response()->json([
                'ok' => false,
                'code' => 'email_not_found',
                'message' => 'No account found for that email.',
            ], 404);
        }

        if ($current !== $next) {
            if (User::where('email', $next)->exists()) {
                return response()->json([
                    'ok' => false,
                    'code' => 'email_taken',
                    'message' => 'That email is already in use.',
                ], 422);
            }

            EmailVerificationCode::where('email', $current)->delete();
            $user->forceFill([
                'email' => $next,
                'email_verified_at' => null,
            ])->save();
        }

        $demoCode = $this->otp->issueAndSend($user->fresh());

        return response()->json([
            'ok' => false,
            'requires_verification' => true,
            'message' => "We've sent a verification code to your email address.",
            'demo_code' => $demoCode,
            'user' => $this->userPayload($user->fresh()),
        ]);
    }

    public function emailStatus(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $seconds = $this->otp->remainingSeconds(strtolower($data['email']));

        return response()->json([
            'ok' => true,
            'remaining_seconds' => $seconds,
        ]);
    }

    public function user(Request $request)
    {
        return response()->json([
            'ok' => true,
            'user' => $this->userPayload($request->user()),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json([
            'ok' => true,
            'message' => 'Logged out.',
        ]);
    }

    private function userPayload(User $user): array
    {
        return [
            'id' => (string) $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'email_verified' => $user->hasVerifiedEmail(),
            'currency' => $user->currency,
            'employment_status' => $user->employment_status,
            'created_at' => optional($user->created_at)?->toIso8601String(),
        ];
    }
}
