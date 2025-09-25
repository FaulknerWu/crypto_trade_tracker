import 'package:flutter/material.dart';

import 'screens/home_page.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '合约交易记账',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066FF)),
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
