<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\AttendanceLog;
use App\Models\File;
use App\Models\Office;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminReadApiTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        Carbon::setTestNow(Carbon::parse('2026-06-09 05:00:00', 'UTC'));
        $this->admin = $this->createUser('Admin Utama', 'ADMIN');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_all_admin_read_endpoints_require_admin_role(): void
    {
        $paths = [
            '/api/v1/admin/dashboard/summary',
            '/api/v1/admin/users',
            '/api/v1/admin/users/'.Str::uuid(),
            '/api/v1/admin/attendances',
            '/api/v1/admin/attendances/report',
            '/api/v1/admin/attendances/'.Str::uuid(),
        ];

        foreach ($paths as $path) {
            $this->getJson($path)->assertUnauthorized()->assertJsonPath('message', 'Unauthorized');
        }

        Sanctum::actingAs($this->createUser('Employee', 'EMPLOYEE'));

        foreach ($paths as $path) {
            $this->getJson($path)->assertForbidden()->assertJsonPath('message', 'Access denied');
        }
    }

    public function test_dashboard_summary_maps_active_users_and_attendance_statuses(): void
    {
        $valid = $this->createUser('Valid User');
        $checkedIn = $this->createUser('Checked User');
        $pending = $this->createUser('Pending User');
        $rejected = $this->createUser('Rejected User');
        $absent = $this->createUser('Absent User');
        $inactive = $this->createUser('Inactive User', 'EMPLOYEE', 'INACTIVE');

        $this->createAttendance($valid, 'VALID');
        $this->createAttendance($checkedIn, 'CHECKED_IN');
        $this->createAttendance($pending, 'PENDING');
        $this->createAttendance($rejected, 'REJECTED');
        $this->createAttendance($inactive, 'VALID');

        Sanctum::actingAs($this->admin);

        $this->getJson('/api/v1/admin/dashboard/summary?date=2026-06-09')
            ->assertOk()
            ->assertJsonPath('data.date', '2026-06-09')
            ->assertJsonPath('data.total', 6)
            ->assertJsonPath('data.present', 1)
            ->assertJsonPath('data.pending', 2)
            ->assertJsonPath('data.absent', 2)
            ->assertJsonPath('data.others', 1);

        $this->assertNotNull($absent);
    }

    public function test_admin_user_list_supports_role_status_search_sort_and_pagination(): void
    {
        $this->createUser('Budi Employee');
        $this->createUser('Citra Inactive', 'EMPLOYEE', 'INACTIVE');
        $this->createUser('Andi Admin', 'ADMIN');

        Sanctum::actingAs($this->admin);

        $this->getJson('/api/v1/admin/users?page=1&pageSize=2&sortOrder=ASC')
            ->assertOk()
            ->assertJsonPath('data.count', 4)
            ->assertJsonPath('data.pageSize', 2)
            ->assertJsonPath('data.pageNum', 2)
            ->assertJsonPath('data.records.0.name', 'Admin Utama')
            ->assertJsonStructure(['data' => ['records' => [['id', 'name', 'email', 'role', 'jabatan', 'status', 'photoUrl', 'createdAt']]]]);

        $this->getJson('/api/v1/admin/users?query=Citra&status=INACTIVE')
            ->assertOk()
            ->assertJsonPath('data.count', 1)
            ->assertJsonPath('data.records.0.name', 'Citra Inactive');
    }

    public function test_admin_can_read_user_detail_and_missing_user_returns_not_found(): void
    {
        $employee = $this->createUser('Detail Employee');
        Sanctum::actingAs($this->admin);

        $this->getJson("/api/v1/admin/users/{$employee->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $employee->id)
            ->assertJsonPath('data.role', 'EMPLOYEE')
            ->assertJsonPath('data.createdAt', '2026-06-09T12:00:00+07:00');

        $this->getJson('/api/v1/admin/users/'.Str::uuid())
            ->assertNotFound()
            ->assertJsonPath('message', 'Not found');
    }

    public function test_admin_attendance_list_filters_user_month_status_and_sort_order(): void
    {
        $employee = $this->createUser('Attendance Employee');
        $other = $this->createUser('Other Employee');
        $juneValid = $this->createAttendance($employee, 'VALID', '2026-06-09');
        $this->createAttendance($employee, 'PENDING', '2026-05-09');
        $this->createAttendance($other, 'VALID', '2026-06-08');

        Sanctum::actingAs($this->admin);

        $this->getJson("/api/v1/admin/attendances?userId={$employee->id}&month=2026-06&status=VALID&sortOrder=ASC")
            ->assertOk()
            ->assertJsonPath('data.count', 1)
            ->assertJsonPath('data.records.0.id', $juneValid->id)
            ->assertJsonPath('data.records.0.userId', $employee->id)
            ->assertJsonPath('data.records.0.officeId', $juneValid->getAttribute('OfficeId'));

        $this->getJson('/api/v1/admin/attendances?pageSize=1')
            ->assertOk()
            ->assertJsonPath('data.count', 3)
            ->assertJsonPath('data.pageSize', 1)
            ->assertJsonPath('data.pageNum', 3);
    }

    public function test_admin_report_returns_active_users_with_nullable_attendance(): void
    {
        $present = $this->createUser('Present User');
        $absent = $this->createUser('Absent User');
        $inactive = $this->createUser('Inactive User', 'EMPLOYEE', 'INACTIVE');
        $attendance = $this->createAttendance($present, 'VALID');
        $this->createAttendance($inactive, 'VALID');

        Sanctum::actingAs($this->admin);

        $response = $this->getJson('/api/v1/admin/attendances/report?date=2026-06-09&pageSize=100')
            ->assertOk()
            ->assertJsonPath('data.count', 3);

        $records = collect($response->json('data.records'))->keyBy('user.id');
        $this->assertSame($attendance->id, $records[$present->id]['attendance']['id']);
        $this->assertNull($records[$absent->id]['attendance']);
        $this->assertFalse($records->has($inactive->id));
    }

    public function test_admin_report_filters_not_checked_in_and_database_status(): void
    {
        $present = $this->createUser('Present User');
        $absent = $this->createUser('Absent User');
        $this->createAttendance($present, 'VALID');

        Sanctum::actingAs($this->admin);

        $this->getJson('/api/v1/admin/attendances/report?date=2026-06-09&status=NOT_CHECKED_IN')
            ->assertOk()
            ->assertJsonPath('data.count', 2)
            ->assertJsonMissing(['id' => $present->id]);

        $this->getJson('/api/v1/admin/attendances/report?date=2026-06-09&status=VALID')
            ->assertOk()
            ->assertJsonPath('data.count', 1)
            ->assertJsonPath('data.records.0.user.id', $present->id)
            ->assertJsonPath('data.records.0.attendance.status', 'VALID');

        $this->getJson('/api/v1/admin/attendances/report?date=2026-06-09&query=Present')
            ->assertOk()
            ->assertJsonPath('data.count', 1)
            ->assertJsonPath('data.records.0.user.id', $present->id);

        $this->assertNotNull($absent);
    }

    public function test_admin_and_employee_detail_include_reject_note_and_complete_admin_fields(): void
    {
        $employee = $this->createUser('Rejected Employee');
        $office = $this->createOffice();
        $photo = $this->createFile($employee);
        $attendance = $this->createAttendance($employee, 'REJECTED', '2026-06-09', $office, $photo);
        AttendanceLog::create([
            'AttendanceId' => $attendance->id,
            'ActorId' => $this->admin->id,
            'statusBefore' => 'PENDING',
            'statusAfter' => 'REJECTED',
            'note' => 'Selfie tidak sesuai.',
        ]);

        Sanctum::actingAs($this->admin);

        $this->getJson("/api/v1/admin/attendances/{$attendance->id}")
            ->assertOk()
            ->assertJsonPath('data.user.id', $employee->id)
            ->assertJsonPath('data.officeId', $office->id)
            ->assertJsonPath('data.officeLatitude', -7.43175)
            ->assertJsonPath('data.selfieUrl', url('/storage/'.$photo->objectKey))
            ->assertJsonPath('data.rejectNote', 'Selfie tidak sesuai.')
            ->assertJsonPath('data.clockInTime', '2026-06-09T08:00:00+07:00');

        Sanctum::actingAs($employee);

        $this->getJson("/api/v1/attendances/{$attendance->id}")
            ->assertOk()
            ->assertJsonPath('data.rejectNote', 'Selfie tidak sesuai.');
    }

    public function test_admin_read_validation_and_not_found_responses_follow_contract(): void
    {
        Sanctum::actingAs($this->admin);

        $this->getJson('/api/v1/admin/dashboard/summary?date=09-06-2026')
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Validation failed');

        $this->getJson('/api/v1/admin/attendances?status=NOT_CHECKED_IN')
            ->assertUnprocessable();

        $this->getJson('/api/v1/admin/attendances/'.Str::uuid())
            ->assertNotFound()
            ->assertJsonPath('message', 'Not found');
    }

    private function createUser(
        string $name,
        string $role = 'EMPLOYEE',
        string $status = 'ACTIVE',
    ): User {
        return User::create([
            'name' => $name,
            'email' => Str::slug($name).'-'.Str::uuid().'@example.com',
            'password' => 'password',
            'role' => $role,
            'jabatan' => 'Staff',
            'status' => $status,
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

    private function createAttendance(
        User $user,
        string $status,
        string $date = '2026-06-09',
        ?Office $office = null,
        ?File $photo = null,
    ): Attendance {
        return Attendance::create([
            'UserId' => $user->id,
            'OfficeId' => ($office ?? $this->createOffice())->id,
            'attendanceDate' => $date,
            'clockInTime' => Carbon::parse("{$date} 01:00:00", 'UTC'),
            'clockOutTime' => in_array($status, ['CHECKED_IN'], true)
                ? null
                : Carbon::parse("{$date} 10:00:00", 'UTC'),
            'clockInLat' => -7.43175,
            'clockInLng' => 109.381309,
            'isOutside' => in_array($status, ['PENDING', 'REJECTED'], true),
            'outsideReason' => in_array($status, ['PENDING', 'REJECTED'], true) ? 'Meeting luar.' : null,
            'clockInPhotoId' => $photo?->id,
            'status' => $status,
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
            'status' => 'CONFIRMED',
            'UserId' => $user->id,
        ]);
    }
}
