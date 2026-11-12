
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_dashboard/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // จำลอง SharedPreferences สำหรับ Widget Test
  SharedPreferences.setMockInitialValues({});

  testWidgets('SKY BUSINESS dashboard loads',
      (WidgetTester tester) async {

    await tester.pumpWidget(const SkyBusinessApp());

    // วาดหน้าจอและรอให้ Future ทำงาน
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // ตรวจสอบว่าแอปเปิดได้
    expect(find.text('SKY BUSINESS'), findsOneWidget);
  });
}
