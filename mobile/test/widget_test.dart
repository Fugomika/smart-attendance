import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendnace/app/app.dart';

void main() {
  testWidgets('Smart Attendance starts at welcome route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartAttendanceApp()));
    await tester.pumpAndSettle();

    expect(find.text('Smart\nAttendance'), findsOneWidget);
    expect(
      find.text('Presensi cerdas dengan\nselfie dan lokasi real-time'),
      findsOneWidget,
    );
  });

  testWidgets('dummy employee login opens employee shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartAttendanceApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    final employeeLoginButton = find.text('Dev Karyawan');
    await tester.ensureVisible(employeeLoginButton);
    await tester.tap(employeeLoginButton);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Status Hari Ini'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Absensi'), findsOneWidget);
  });

  testWidgets('dummy admin login opens admin shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartAttendanceApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    final adminLoginButton = find.text('Dev Admin');
    await tester.ensureVisible(adminLoginButton);
    await tester.tap(adminLoginButton);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Total Karyawan Aktif'), findsOneWidget);

    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();

    expect(find.text('Admin Laporan placeholder.'), findsOneWidget);
  });
}
