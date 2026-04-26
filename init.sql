-- =========================
-- DATABASE
-- =========================
DROP DATABASE IF EXISTS db_smart_attendance;
CREATE DATABASE db_smart_attendance;
USE db_smart_attendance;

-- =========================
-- TABLE: tb_user
-- =========================
CREATE TABLE `tb_user` (
  `id` char(36) NOT NULL COMMENT 'Primary key (UUID)',
  `name` varchar(100) NOT NULL COMMENT 'Full name of user',
  `email` varchar(100) NOT NULL COMMENT 'User email (must be unique)',
  `password` varchar(255) NOT NULL COMMENT 'Hashed password',
  `role` enum('ADMIN','EMPLOYEE') NOT NULL COMMENT 'User role: ADMIN or EMPLOYEE',
  `jabatan` varchar(100) DEFAULT NULL COMMENT 'Job position/title',
  `status` enum('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE' COMMENT 'User status: ACTIVE or INACTIVE',
  `PhotoId` char(36) DEFAULT NULL COMMENT 'FK to tb_file (profile photo)',
  `createdAt` datetime NOT NULL COMMENT 'Record creation timestamp',
  `updatedAt` datetime DEFAULT NULL COMMENT 'Last update timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='User master data';

-- =========================
-- TABLE: tb_file
-- =========================
CREATE TABLE `tb_file` (
  `id` char(36) NOT NULL COMMENT 'Primary key (UUID)',
  `objectKey` varchar(255) NOT NULL COMMENT 'File path in storage (unique)',
  `originalName` varchar(255) NOT NULL COMMENT 'Original filename from user',
  `bucket` varchar(50) NOT NULL COMMENT 'Storage bucket name',
  `contentType` varchar(127) NOT NULL COMMENT 'MIME type (e.g. image/jpeg)',
  `context` varchar(50) DEFAULT NULL COMMENT 'Usage context: profile_photo, attendance_selfie',
  `isPublic` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Access flag (1=public, 0=private)',
  `status` enum('PENDING','CONFIRMED','DELETED') NOT NULL DEFAULT 'PENDING' COMMENT 'File lifecycle status',
  `UserId` char(36) NOT NULL COMMENT 'User ID who uploaded the file (soft reference)',
  `createdAt` datetime NOT NULL COMMENT 'Record creation timestamp',
  `updatedAt` datetime DEFAULT NULL COMMENT 'Last update timestamp',
  `deletedAt` datetime DEFAULT NULL COMMENT 'Soft delete timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_file_object_key_unique` (`objectKey`),
  KEY `idx_file_user_id` (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='File storage metadata';

-- =========================
-- TABLE: tb_office
-- =========================
CREATE TABLE `tb_office` (
  `id` char(36) NOT NULL COMMENT 'Primary key (UUID)',
  `officeName` varchar(100) NOT NULL COMMENT 'Office name',
  `latitude` decimal(10,7) NOT NULL COMMENT 'Office latitude coordinate',
  `longitude` decimal(10,7) NOT NULL COMMENT 'Office longitude coordinate',
  `radiusMeter` int NOT NULL COMMENT 'Allowed attendance radius in meters',
  `isActive` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Active flag for office',
  `createdAt` datetime NOT NULL COMMENT 'Record creation timestamp',
  `updatedAt` datetime DEFAULT NULL COMMENT 'Last update timestamp',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Office configuration';

-- =========================
-- TABLE: tb_attendance
-- =========================
CREATE TABLE `tb_attendance` (
  `id` char(36) NOT NULL COMMENT 'Primary key (UUID)',
  `UserId` char(36) NOT NULL COMMENT 'FK to tb_user',
  `OfficeId` char(36) DEFAULT NULL COMMENT 'FK to tb_office',

  `attendanceDate` date NOT NULL COMMENT 'Attendance date',

  `clockInTime` datetime DEFAULT NULL COMMENT 'Clock in timestamp',
  `clockOutTime` datetime DEFAULT NULL COMMENT 'Clock out timestamp',

  `clockInLat` decimal(10,7) DEFAULT NULL COMMENT 'Latitude at clock in',
  `clockInLng` decimal(10,7) DEFAULT NULL COMMENT 'Longitude at clock in',

  `isOutside` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Flag if attendance outside office',
  `outsideReason` varchar(255) DEFAULT NULL COMMENT 'Reason for outside attendance',

  `clockInPhotoId` char(36) DEFAULT NULL COMMENT 'FK to tb_file (selfie photo)',

  `status` enum(
    'CHECKED_IN',
    'PENDING',
    'VALID',
    'REJECTED',
    'SICK',
    'LEAVE',
    'HOLIDAY'
  ) NOT NULL COMMENT 'Attendance status:
CHECKED_IN = clock in only
PENDING = waiting admin approval (outside)
VALID = approved/normal attendance
REJECTED = rejected by admin
SICK = sick leave
LEAVE = personal leave
HOLIDAY = holiday',

  `createdAt` datetime NOT NULL COMMENT 'Record creation timestamp',
  `updatedAt` datetime DEFAULT NULL COMMENT 'Last update timestamp',

  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_attendance_user_date_unique` (`UserId`,`attendanceDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Attendance records';

-- =========================
-- TABLE: tb_attendance_log
-- =========================
CREATE TABLE `tb_attendance_log` (
  `id` char(36) NOT NULL COMMENT 'Primary key (UUID)',
  `AttendanceId` char(36) NOT NULL COMMENT 'FK to tb_attendance',

  `statusBefore` varchar(50) DEFAULT NULL COMMENT 'Previous status',
  `statusAfter` varchar(50) NOT NULL COMMENT 'New status',

  `note` varchar(255) DEFAULT NULL COMMENT 'Note or reason for change',

  `createdAt` datetime NOT NULL COMMENT 'Record creation timestamp',
  `updatedAt` datetime DEFAULT NULL COMMENT 'Last update timestamp',

  PRIMARY KEY (`id`),
  KEY `idx_attendance_log_attendance` (`AttendanceId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Attendance status change log';

-- =========================
-- TABLE: tb_holiday
-- =========================
CREATE TABLE `tb_holiday` (
  `id` char(36) NOT NULL COMMENT 'Primary key (UUID)',
  `startDate` date NOT NULL COMMENT 'Holiday start date',
  `endDate` date NOT NULL COMMENT 'Holiday end date',
  `holidayName` varchar(100) NOT NULL COMMENT 'Holiday name',
  `holidayType` enum('NATIONAL','COMPANY') NOT NULL COMMENT 'Holiday type',
  `createdAt` datetime NOT NULL COMMENT 'Record creation timestamp',
  `updatedAt` datetime DEFAULT NULL COMMENT 'Last update timestamp',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Holiday configuration';

-- =========================
-- FOREIGN KEYS
-- =========================

ALTER TABLE `tb_user`
ADD CONSTRAINT `fk_user_photo`
FOREIGN KEY (`PhotoId`) REFERENCES `tb_file`(`id`);

ALTER TABLE `tb_attendance`
ADD CONSTRAINT `fk_attendance_user`
FOREIGN KEY (`UserId`) REFERENCES `tb_user`(`id`);

ALTER TABLE `tb_attendance`
ADD CONSTRAINT `fk_attendance_office`
FOREIGN KEY (`OfficeId`) REFERENCES `tb_office`(`id`);

ALTER TABLE `tb_attendance`
ADD CONSTRAINT `fk_attendance_photo`
FOREIGN KEY (`clockInPhotoId`) REFERENCES `tb_file`(`id`);

ALTER TABLE `tb_attendance_log`
ADD CONSTRAINT `fk_attendance_log_attendance`
FOREIGN KEY (`AttendanceId`) REFERENCES `tb_attendance`(`id`);
