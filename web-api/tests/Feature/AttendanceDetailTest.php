<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\Office;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AttendanceDetailTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_can_read_attendance_detail_with_office_location_fields(): void
    {
        $user = $this->createUser('owner@example.com');
        $office = Office::create([
            'officeName' => 'Kantor Pusat',
            'latitude' => -6.2088000,
            'longitude' => 106.8456000,
            'radiusMeter' => 100,
            'isActive' => true,
        ]);
        $attendance = Attendance::create([
            'UserId' => $user->id,
            'OfficeId' => $office->id,
            'attendanceDate' => '2026-06-09',
            'clockInTime' => Carbon::parse('2026-06-09 08:00:00', 'UTC'),
            'clockOutTime' => Carbon::parse('2026-06-09 10:00:00', 'UTC'),
            'clockInLat' => -6.2200000,
            'clockInLng' => 106.8500000,
            'isOutside' => false,
            'status' => 'VALID',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/attendances/{$attendance->id}")
            ->assertOk()
            ->assertJsonPath('message', 'Data retrieved successfully')
            ->assertJsonPath('data.officeId', $office->id)
            ->assertJsonPath('data.officeName', 'Kantor Pusat')
            ->assertJsonPath('data.officeLatitude', -6.2088)
            ->assertJsonPath('data.officeLongitude', 106.8456)
            ->assertJsonPath('data.officeRadiusMeter', 100)
            ->assertJsonPath('data.clockInTime', '2026-06-09T15:00:00+07:00')
            ->assertJsonPath('data.clockOutTime', '2026-06-09T17:00:00+07:00')
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'attendanceDate',
                    'status',
                    'clockInTime',
                    'clockOutTime',
                    'clockInLat',
                    'clockInLng',
                    'isOutside',
                    'outsideReason',
                    'officeId',
                    'officeName',
                    'officeLatitude',
                    'officeLongitude',
                    'officeRadiusMeter',
                    'selfieUrl',
                    'createdAt',
                    'updatedAt',
                ],
            ]);
    }

    public function test_office_location_fields_are_null_when_attendance_has_no_office(): void
    {
        $user = $this->createUser('without-office@example.com');
        $attendance = Attendance::create([
            'UserId' => $user->id,
            'OfficeId' => null,
            'attendanceDate' => '2026-06-09',
            'status' => 'SICK',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/v1/attendances/{$attendance->id}")
            ->assertOk()
            ->assertJsonPath('data.officeId', null)
            ->assertJsonPath('data.officeName', null)
            ->assertJsonPath('data.officeLatitude', null)
            ->assertJsonPath('data.officeLongitude', null)
            ->assertJsonPath('data.officeRadiusMeter', null);
    }

    public function test_unauthenticated_user_cannot_read_attendance_detail(): void
    {
        $this->getJson('/api/v1/attendances/'.Str::uuid())
            ->assertUnauthorized()
            ->assertJsonPath('message', 'Unauthorized');
    }

    public function test_user_cannot_read_another_users_attendance_detail(): void
    {
        $owner = $this->createUser('attendance-owner@example.com');
        $otherUser = $this->createUser('other-user@example.com');
        $attendance = Attendance::create([
            'UserId' => $owner->id,
            'OfficeId' => null,
            'attendanceDate' => '2026-06-09',
            'status' => 'LEAVE',
        ]);

        Sanctum::actingAs($otherUser);

        $this->getJson("/api/v1/attendances/{$attendance->id}")
            ->assertForbidden()
            ->assertJsonPath('message', 'Access denied');
    }

    public function test_missing_attendance_returns_not_found(): void
    {
        Sanctum::actingAs($this->createUser('not-found@example.com'));

        $this->getJson('/api/v1/attendances/'.Str::uuid())
            ->assertNotFound()
            ->assertJsonPath('message', 'Not found');
    }

    private function createUser(string $email): User
    {
        return User::create([
            'name' => 'Test User',
            'email' => $email,
            'password' => 'password',
            'role' => 'EMPLOYEE',
            'status' => 'ACTIVE',
        ]);
    }
}
