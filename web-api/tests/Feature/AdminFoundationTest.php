<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\AttendanceLog;
use App\Models\File;
use App\Models\Office;
use App\Models\User;
use App\Services\AttendanceTransitionService;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use RuntimeException;
use Tests\TestCase;

class AdminFoundationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Route::middleware(['api', 'auth:sanctum', 'admin'])
            ->get('/api/v1/admin/l1-probe', fn () => response()->json(['message' => 'ok']));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_admin_route_requires_authentication(): void
    {
        $this->getJson('/api/v1/admin/l1-probe')
            ->assertUnauthorized()
            ->assertJsonPath('message', 'Unauthorized');
    }

    public function test_admin_route_rejects_authenticated_employee(): void
    {
        Sanctum::actingAs($this->createUser('EMPLOYEE'));

        $this->getJson('/api/v1/admin/l1-probe')
            ->assertForbidden()
            ->assertJsonPath('message', 'Access denied');
    }

    public function test_admin_route_allows_authenticated_admin(): void
    {
        Sanctum::actingAs($this->createUser('ADMIN'));

        $this->getJson('/api/v1/admin/l1-probe')
            ->assertOk()
            ->assertJsonPath('message', 'ok');
    }

    public function test_attendance_log_relations_use_custom_foreign_keys(): void
    {
        $actor = $this->createUser('ADMIN');
        $attendance = $this->createAttendance($actor);
        $log = AttendanceLog::create([
            'AttendanceId' => $attendance->id,
            'ActorId' => $actor->id,
            'statusBefore' => null,
            'statusAfter' => 'CHECKED_IN',
        ]);

        $this->assertTrue($attendance->logs()->whereKey($log->id)->exists());
        $this->assertTrue($log->actor->is($actor));
    }

    public function test_clock_in_creates_log_with_current_user_as_actor(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-06-09 01:00:00', 'UTC'));

        $user = $this->createUser('EMPLOYEE');
        $office = $this->createOffice();
        $photo = $this->createFile($user);
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/attendances/clock-in', [
            'officeId' => $office->id,
            'clockInLat' => $office->latitude,
            'clockInLng' => $office->longitude,
            'isOutside' => false,
            'outsideReason' => null,
            'clockInPhotoId' => $photo->id,
        ]);

        $response->assertCreated()->assertJsonPath('data.status', 'CHECKED_IN');

        $attendance = Attendance::findOrFail($response->json('data.id'));
        $this->assertDatabaseHas('attendance_logs', [
            'AttendanceId' => $attendance->id,
            'ActorId' => $user->id,
            'statusBefore' => null,
            'statusAfter' => 'CHECKED_IN',
        ]);
        $this->assertDatabaseHas('files', ['id' => $photo->id, 'status' => 'CONFIRMED']);
    }

    public function test_clock_out_creates_log_with_current_user_as_actor(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-06-09 10:00:00', 'UTC'));

        $user = $this->createUser('EMPLOYEE');
        $attendance = $this->createAttendance($user);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/attendances/clock-out', [
            'attendanceId' => $attendance->id,
        ])->assertOk()->assertJsonPath('data.status', 'VALID');

        $this->assertDatabaseHas('attendance_logs', [
            'AttendanceId' => $attendance->id,
            'ActorId' => $user->id,
            'statusBefore' => 'CHECKED_IN',
            'statusAfter' => 'VALID',
        ]);
    }

    public function test_initial_attendance_write_rolls_back_when_follow_up_write_fails(): void
    {
        $user = $this->createUser('EMPLOYEE');
        $service = app(AttendanceTransitionService::class);

        try {
            $service->create(
                fn (): Attendance => $this->createAttendance($user),
                $user,
                fn () => throw new RuntimeException('Follow-up write failed'),
            );

            $this->fail('Expected initial attendance transaction to fail.');
        } catch (RuntimeException) {
            $this->assertDatabaseCount('attendances', 0);
            $this->assertDatabaseCount('attendance_logs', 0);
        }
    }

    public function test_status_transition_rolls_back_when_log_insert_fails(): void
    {
        $user = $this->createUser('EMPLOYEE');
        $attendance = $this->createAttendance($user);
        $missingActor = new User(['role' => 'ADMIN']);
        $missingActor->id = (string) Str::uuid();
        $service = app(AttendanceTransitionService::class);

        try {
            $service->transition(
                $attendance,
                'VALID',
                $missingActor,
                ['CHECKED_IN'],
                ['clockOutTime' => now()],
            );

            $this->fail('Expected attendance log insert to fail.');
        } catch (QueryException) {
            $attendance->refresh();

            $this->assertSame('CHECKED_IN', $attendance->status);
            $this->assertNull($attendance->clockOutTime);
            $this->assertDatabaseCount('attendance_logs', 0);
        }
    }

    private function createUser(string $role): User
    {
        return User::create([
            'name' => "{$role} Test",
            'email' => strtolower($role).'-'.Str::uuid().'@example.com',
            'password' => 'password',
            'role' => $role,
            'status' => 'ACTIVE',
        ]);
    }

    private function createOffice(): Office
    {
        return Office::create([
            'officeName' => 'Kantor Pusat',
            'latitude' => -7.43175,
            'longitude' => 109.381309,
            'radiusMeter' => 500,
            'isActive' => true,
        ]);
    }

    private function createAttendance(User $user): Attendance
    {
        return Attendance::create([
            'UserId' => $user->id,
            'OfficeId' => $this->createOffice()->id,
            'attendanceDate' => '2026-06-09',
            'clockInTime' => Carbon::parse('2026-06-09 01:00:00', 'UTC'),
            'isOutside' => false,
            'status' => 'CHECKED_IN',
        ]);
    }

    private function createFile(User $user): File
    {
        return File::create([
            'objectKey' => 'uploads/attendance_selfie/'.Str::uuid().'.jpg',
            'originalName' => 'selfie.jpg',
            'bucket' => 'public',
            'contentType' => 'image/jpeg',
            'context' => 'attendance_selfie',
            'isPublic' => true,
            'status' => 'PENDING',
            'UserId' => $user->id,
        ]);
    }
}
