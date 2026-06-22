<?php

namespace App\Services;

use Illuminate\Support\Facades\Mail;

class MailService
{
    public function send(string $to, string $subject, string $body): void
    {
        Mail::raw($body, fn ($message) => $message->to($to)->subject($subject));
    }
}
