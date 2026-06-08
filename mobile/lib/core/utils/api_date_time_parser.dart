class ApiDateTimeParser {
  const ApiDateTimeParser._();

  static DateTime? timestamp(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw)?.toLocal();
  }

  static DateTime? dateOnly(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parts = raw.split('-');
    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }

    final date = DateTime(year, month, day);
    final isValid = date.year == year && date.month == month && date.day == day;
    return isValid ? date : null;
  }
}
