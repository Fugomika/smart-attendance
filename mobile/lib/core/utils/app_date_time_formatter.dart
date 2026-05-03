class AppDateTimeFormatter {
  const AppDateTimeFormatter._();

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String dateLong(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  static String monthYear(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  static String time(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static bool isSameMonth(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month;
  }
}
