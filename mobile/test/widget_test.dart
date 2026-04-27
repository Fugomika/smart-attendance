import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendnace/app/app.dart';

void main() {
  testWidgets('Smart Attendance starts at welcome route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartAttendanceApp()));
    await tester.pumpAndSettle();

    expect(find.text('Smart Attendance'), findsOneWidget);
    expect(find.text('Boilerplate welcome route is ready.'), findsOneWidget);
  });

  testWidgets('dummy employee login opens employee shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartAttendanceApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ke Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login Employee'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Employee Home placeholder.'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    expect(find.text('Employee Riwayat placeholder.'), findsOneWidget);
  });

  testWidgets('dummy admin login opens admin shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartAttendanceApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ke Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login Admin'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Admin Dashboard placeholder.'), findsOneWidget);

    await tester.tap(find.text('Laporan'));
    await tester.pumpAndSettle();

    expect(find.text('Admin Laporan placeholder.'), findsOneWidget);
  });
}
