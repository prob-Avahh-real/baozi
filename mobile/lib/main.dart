import 'package:flutter/material.dart';
import 'common/fonts/font_manager.dart';
import 'common/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化字体分包加载器
  await FontManager.instance.init();
  // 预载首页中文文本所需的分块
  await FontManager.instance.ensureLoaded('宝子欢迎使用你的随身工具');

  runApp(const BaoziApp());
}

class BaoziApp extends StatelessWidget {
  const BaoziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '宝子',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('宝子')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '欢迎使用宝子',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '你的随身工具',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
