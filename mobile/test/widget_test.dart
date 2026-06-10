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
}
