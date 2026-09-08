<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class VerificationCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $userName,
        public string $code,
        public int $expiresMinutes,
    ) {
    }

    public function build()
    {
        $name = e($this->userName);
        $code = e($this->code);
        $minutes = e((string) $this->expiresMinutes);

        $html = <<<HTML
        <div style="font-family: Arial, sans-serif; line-height: 1.5; color: #222;">
          <h2>Verify your Pockify email</h2>
          <p>Hi {$name},</p>
          <p>Use this verification code to activate your account:</p>
          <p style="font-size: 28px; font-weight: 700; letter-spacing: 4px;">{$code}</p>
          <p>This code expires in {$minutes} minutes.</p>
          <p>If you did not create a Pockify account, you can ignore this email.</p>
        </div>
        HTML;

        return $this->subject('Your Pockify verification code')->html($html);
    }
}
