<?php

namespace Tests\Feature;

use App\Models\File;
use App\Models\User;
use App\Services\RegistrationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;
use Tests\TestCase;

class AuthEnhancementsTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_without_avatar_remains_supported(): void
    {
        $this->postJson('/api/v1/auth/register', $this->registerData())
            ->assertCreated()
            ->assertJsonPath('message', 'Registration successful')
            ->assertJsonPath('data.role', 'EMPLOYEE')
            ->assertJsonPath('data.status', 'ACTIVE')
            ->assertJsonPath('data.photoUrl', null);

        $this->assertDatabaseHas('users', [
            'email' => 'register@example.com',
            'role' => 'EMPLOYEE',
            'status' => 'ACTIVE',
            'PhotoId' => null,
        ]);
    }

    public function test_register_with_avatar_creates_confirmed_profile_file_and_attaches_it(): void
    {
        Storage::fake('public');

        $response = $this->post('/api/v1/auth/register', [
            ...$this->registerData(),
            'avatar' => UploadedFile::fake()->image('avatar.jpg', 300, 300),
        ], ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonPath('data.photoUrl', fn ($url) => is_string($url) && str_contains($url, '/storage/uploads/profile_photo/'));

        $user = User::with('photo')->findOrFail($response->json('data.id'));

        $this->assertNotNull($user->getAttribute('PhotoId'));
        $this->assertSame('profile_photo', $user->photo->context);
        $this->assertSame('CONFIRMED', $user->photo->status);
        $this->assertSame($user->id, $user->photo->getAttribute('UserId'));
        Storage::disk('public')->assertExists($user->photo->objectKey);
    }

    public function test_register_accepts_supported_avatar_formats(): void
    {
        Storage::fake('public');

        $avatars = [
            UploadedFile::fake()->image('avatar.jpg'),
            UploadedFile::fake()->image('avatar.jpeg'),
            UploadedFile::fake()->image('avatar.png'),
            UploadedFile::fake()->createWithContent('avatar.webp', $this->webpContent()),
        ];

        foreach ($avatars as $index => $avatar) {
            $this->post('/api/v1/auth/register', [
                ...$this->registerData("format-{$index}@example.com"),
                'avatar' => $avatar,
            ], ['Accept' => 'application/json'])->assertCreated();
        }

        $this->assertDatabaseCount('users', 4);
        $this->assertDatabaseCount('files', 4);
    }

    public function test_register_rejects_invalid_avatar_oversized_avatar_duplicate_email_and_photo_id(): void
    {
        Storage::fake('public');
        User::create([
            'name' => 'Existing',
            'email' => 'existing@example.com',
            'password' => 'password',
            'role' => 'EMPLOYEE',
            'status' => 'ACTIVE',
        ]);

        $this->post('/api/v1/auth/register', [
            ...$this->registerData('invalid@example.com'),
            'avatar' => UploadedFile::fake()->create('avatar.txt', 10, 'text/plain'),
        ], ['Accept' => 'application/json'])->assertUnprocessable();

        $this->post('/api/v1/auth/register', [
            ...$this->registerData('oversized@example.com'),
            'avatar' => UploadedFile::fake()->image('avatar.jpg')->size(5121),
        ], ['Accept' => 'application/json'])->assertUnprocessable();

        $this->postJson('/api/v1/auth/register', $this->registerData('existing@example.com'))
            ->assertConflict()
            ->assertJsonPath('message', 'Email already registered');

        $this->postJson('/api/v1/auth/register', [
            ...$this->registerData('photo-id@example.com'),
            'photoId' => (string) Str::uuid(),
        ])->assertUnprocessable();
    }

    public function test_register_rolls_back_database_and_physical_avatar_when_processing_fails(): void
    {
        Storage::fake('public');

        $this->app->instance(RegistrationService::class, new class extends RegistrationService
        {
            protected function afterAvatarStored(User $user, File $file): void
            {
                throw new RuntimeException('Attachment processing failed.');
            }
        });

        try {
            $this->post('/api/v1/auth/register', [
                ...$this->registerData(),
                'avatar' => UploadedFile::fake()->image('avatar.jpg'),
            ], ['Accept' => 'application/json']);

            $this->fail('Expected registration processing to fail.');
        } catch (RuntimeException) {
            $this->assertDatabaseCount('users', 0);
            $this->assertDatabaseCount('files', 0);
            $this->assertSame([], Storage::disk('public')->allFiles());
        }
    }

    public function test_forgot_password_validates_email_existence(): void
    {
        User::create([
            'name' => 'Registered User',
            'email' => 'registered@example.com',
            'password' => 'password',
            'role' => 'EMPLOYEE',
            'status' => 'ACTIVE',
        ]);

        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'registered@example.com'])
            ->assertOk()
            ->assertJsonPath('message', 'Email terdaftar')
            ->assertJsonPath('data', null);

        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'missing@example.com'])
            ->assertNotFound()
            ->assertJsonPath('message', 'Email tidak terdaftar');

        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'invalid-email'])
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Validation failed');
    }

    /**
     * @return array<string, string>
     */
    private function registerData(string $email = 'register@example.com'): array
    {
        return [
            'name' => 'Register User',
            'email' => $email,
            'password' => 'password',
            'jabatan' => 'Staff IT',
        ];
    }

    private function webpContent(): string
    {
        return base64_decode('UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA');
    }
}
