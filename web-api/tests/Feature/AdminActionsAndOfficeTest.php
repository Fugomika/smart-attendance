<?php

namespace Tests\Feature;

use App\Filament\Resources\Attendances\AttendanceResource;
use App\Filament\Resources\Offices\OfficeResource;
use App\Models\Attendance;
use App\Models\Office;
use App\Models\User;
use App\Services\ActiveOfficeService;
use DomainException;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminActionsAndOfficeTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private ActiveOfficeService $activeOfficeService;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = $this->createUser('ADMIN');
        $this->activeOfficeService = app(ActiveOfficeService::class);
    }

    public function test_admin_can_approve_pending_attendance_with_actor_and_without_note(): void
    {
        $attendance = $this->createAttendance('PENDING');
        Sanctum::actingAs($this->admin);

        $this->patchJson("/api/v1/admin/attendances/{$attendance->id}/validation", [
            'status' => 'VALID',
            'note' => 'This note must be ignored.',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'VALID')
            ->assertJsonPath('data.rejectNote', null);

        $this->assertDatabaseHas('attendance_logs', [
            'AttendanceId' => $attendance->id,
            'ActorId' => $this->admin->id,
            'statusBefore' => 'PENDING',
            'statusAfter' => 'VALID',
            'note' => null,
        ]);
    }

    public function test_admin_can_reject_pending_attendance_with_optional_note_and_actor(): void
    {
        $attendance = $this->createAttendance('PENDING');
        Sanctum::actingAs($this->admin);

        $this->patchJson("/api/v1/admin/attendances/{$attendance->id}/validation", [
            'status' => 'REJECTED',
            'note' => 'Selfie tidak sesuai.',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'REJECTED')
            ->assertJsonPath('data.rejectNote', 'Selfie tidak sesuai.');

        $this->assertDatabaseHas('attendance_logs', [
            'AttendanceId' => $attendance->id,
            'ActorId' => $this->admin->id,
            'statusBefore' => 'PENDING',
            'statusAfter' => 'REJECTED',
            'note' => 'Selfie tidak sesuai.',
        ]);
    }

    public function test_validation_rejects_non_pending_repeated_and_invalid_requests(): void
    {
        $attendance = $this->createAttendance('VALID');
        Sanctum::actingAs($this->admin);

        $this->patchJson("/api/v1/admin/attendances/{$attendance->id}/validation", [
            'status' => 'REJECTED',
        ])->assertBadRequest()->assertJsonPath('message', 'Attendance status is not PENDING');

        $pending = $this->createAttendance('PENDING');
        $path = "/api/v1/admin/attendances/{$pending->id}/validation";

        $this->patchJson($path, ['status' => 'VALID'])->assertOk();
        $this->patchJson($path, ['status' => 'REJECTED'])->assertBadRequest();

        $this->assertDatabaseCount('attendance_logs', 1);

        $this->patchJson($path, ['status' => 'PENDING'])
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Validation failed');

        $this->patchJson($path, [
            'status' => 'REJECTED',
            'note' => str_repeat('a', 256),
        ])->assertUnprocessable();

        $this->patchJson('/api/v1/admin/attendances/'.Str::uuid().'/validation', [
            'status' => 'VALID',
        ])->assertNotFound();
    }

    public function test_validation_and_office_update_require_admin_role(): void
    {
        $attendance = $this->createAttendance('PENDING');
        $office = $this->activeOfficeService->create($this->officeData('Active'));

        $this->patchJson("/api/v1/admin/attendances/{$attendance->id}/validation", [
            'status' => 'VALID',
        ])->assertUnauthorized();

        $this->patchJson("/api/v1/admin/offices/{$office->id}", $this->officeData('Updated'))
            ->assertUnauthorized();

        $employee = $this->createUser('EMPLOYEE');
        Sanctum::actingAs($employee);

        $this->patchJson("/api/v1/admin/attendances/{$attendance->id}/validation", [
            'status' => 'VALID',
        ])->assertForbidden();

        $this->patchJson("/api/v1/admin/offices/{$office->id}", $this->officeData('Updated'))
            ->assertForbidden();
    }

    public function test_admin_can_update_only_active_office(): void
    {
        $active = $this->activeOfficeService->create($this->officeData('Active'));
        $inactive = $this->activeOfficeService->create([
            ...$this->officeData('Inactive'),
            'isActive' => false,
        ]);
        Sanctum::actingAs($this->admin);

        $this->patchJson("/api/v1/admin/offices/{$active->id}", [
            'officeName' => 'Kantor Pusat Baru',
            'latitude' => -6.2,
            'longitude' => 106.8,
            'radiusMeter' => 300,
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Office updated successfully')
            ->assertJsonPath('data.officeName', 'Kantor Pusat Baru')
            ->assertJsonPath('data.isActive', true);

        $this->patchJson("/api/v1/admin/offices/{$inactive->id}", $this->officeData('Cannot Update'))
            ->assertNotFound();

        $this->patchJson('/api/v1/admin/offices/'.Str::uuid(), $this->officeData('Missing'))
            ->assertNotFound();

        $this->patchJson("/api/v1/admin/offices/{$active->id}", [
            'officeName' => '',
            'latitude' => -91,
            'longitude' => 181,
            'radiusMeter' => 0,
        ])
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Validation failed');
    }

    public function test_admin_office_update_rejects_duplicate_name_but_allows_current_name(): void
    {
        $active = $this->activeOfficeService->create($this->officeData('Active Office'));
        $this->activeOfficeService->create([
            ...$this->officeData('Other Office'),
            'isActive' => false,
        ]);
        Sanctum::actingAs($this->admin);

        $this->patchJson("/api/v1/admin/offices/{$active->id}", $this->officeData('Other Office'))
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Validation failed')
            ->assertJsonPath('errors.0.path', 'officeName');

        $this->patchJson("/api/v1/admin/offices/{$active->id}", $this->officeData('Active Office'))
            ->assertOk()
            ->assertJsonPath('data.officeName', 'Active Office');
    }

    public function test_database_rejects_duplicate_office_name_from_shared_service(): void
    {
        $this->activeOfficeService->create($this->officeData('Unique Office'));

        $this->expectException(UniqueConstraintViolationException::class);

        $this->activeOfficeService->create([
            ...$this->officeData('Unique Office'),
            'isActive' => false,
        ]);
    }

    public function test_active_office_service_keeps_exactly_one_active_office(): void
    {
        $first = $this->activeOfficeService->create([
            ...$this->officeData('First'),
            'isActive' => false,
        ]);
        $second = $this->activeOfficeService->create([
            ...$this->officeData('Second'),
            'isActive' => false,
        ]);

        $this->assertTrue($first->fresh()->isActive);
        $this->assertFalse($second->fresh()->isActive);
        $this->assertSame(1, Office::where('isActive', true)->count());

        $second = $this->activeOfficeService->update($second, ['isActive' => true]);

        $this->assertTrue($second->isActive);
        $this->assertFalse($first->fresh()->isActive);
        $this->assertSame(1, Office::where('isActive', true)->count());
    }

    public function test_active_office_cannot_be_deactivated_or_deleted_without_replacement(): void
    {
        $active = $this->activeOfficeService->create($this->officeData('Active'));

        try {
            $this->activeOfficeService->update($active, ['isActive' => false]);
            $this->fail('Expected active office deactivation to fail.');
        } catch (DomainException) {
            $this->assertTrue($active->fresh()->isActive);
        }

        try {
            $this->activeOfficeService->delete($active);
            $this->fail('Expected active office deletion to fail.');
        } catch (DomainException) {
            $this->assertDatabaseHas('offices', ['id' => $active->id, 'isActive' => true]);
        }
    }

    public function test_inactive_office_can_be_deleted_through_shared_behavior(): void
    {
        $this->activeOfficeService->create($this->officeData('Active'));
        $inactive = $this->activeOfficeService->create([
            ...$this->officeData('Inactive'),
            'isActive' => false,
        ]);

        $this->activeOfficeService->delete($inactive);

        $this->assertDatabaseMissing('offices', ['id' => $inactive->id]);
        $this->assertSame(1, Office::where('isActive', true)->count());
    }

    public function test_filament_attendance_resource_disables_create_and_delete(): void
    {
        $attendance = $this->createAttendance('PENDING');

        $this->assertFalse(AttendanceResource::canCreate());
        $this->assertFalse(AttendanceResource::canDelete($attendance));
        $this->assertFalse(AttendanceResource::canDeleteAny());
        $this->assertArrayNotHasKey('create', AttendanceResource::getPages());
    }

    public function test_filament_office_resource_blocks_active_and_bulk_delete(): void
    {
        $active = $this->activeOfficeService->create($this->officeData('Active'));
        $inactive = $this->activeOfficeService->create([
            ...$this->officeData('Inactive'),
            'isActive' => false,
        ]);

        $this->assertFalse(OfficeResource::canDelete($active));
        $this->assertTrue(OfficeResource::canDelete($inactive));
        $this->assertFalse(OfficeResource::canDeleteAny());
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

    private function createAttendance(string $status): Attendance
    {
        $user = $this->createUser('EMPLOYEE');

        return Attendance::create([
            'UserId' => $user->id,
            'attendanceDate' => '2026-06-09',
            'isOutside' => true,
            'status' => $status,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function officeData(string $name): array
    {
        return [
            'officeName' => $name,
            'latitude' => -7.43175,
            'longitude' => 109.381309,
            'radiusMeter' => 500,
            'isActive' => true,
        ];
    }
}
