import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendnace/app/app.dart';

void main() {
  testWidgets('Smart Attendance starts at welcome route', (tester) async {
    await tester.pumpWidget(const SmartAttendanceApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart Attendance'), findsOneWidget);
    expect(find.text('Boilerplate welcome route is ready.'), findsOneWidget);
  });
}
