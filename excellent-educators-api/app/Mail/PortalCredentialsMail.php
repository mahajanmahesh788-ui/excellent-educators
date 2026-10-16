<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class PortalCredentialsMail extends Mailable
{
    use Queueable, SerializesModels;

    /**
     * @param  array{role_label: string, login_url: string, temporary_password: string, student_code?: string|null}  $context
     */
    public function __construct(
        public readonly User $user,
        public readonly array $context,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Your Excellent Educators account is ready',
        );
    }

    public function content(): Content
    {
        return new Content(
            html: 'emails.portal-credentials',
            text: 'emails.portal-credentials-text',
            with: [
                'recipientName' => $this->user->name,
                'email' => $this->user->email,
                'roleLabel' => $this->context['role_label'],
                'loginUrl' => $this->context['login_url'],
                'temporaryPassword' => $this->context['temporary_password'],
                'studentCode' => $this->context['student_code'] ?? null,
                'appName' => (string) config('app.name', 'Excellent Educators'),
            ],
        );
    }
}
