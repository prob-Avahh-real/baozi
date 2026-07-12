import 'package:flutter_test/flutter_test.dart';

import 'package:baozi/main.dart';

void main() {
  testWidgets('宝子首页显示欢迎文案', (WidgetTester tester) async {
    await tester.pumpWidget(const BaoziApp());

    // 验证中文标题和欢迎文案
    expect(find.text('宝子'), findsOneWidget);
    expect(find.text('欢迎使用宝子'), findsOneWidget);
    expect(find.text('你的随身工具'), findsOneWidget);
  });
}
