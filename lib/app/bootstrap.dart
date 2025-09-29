import 'dart:async';

import 'package:flutter/material.dart';

import '../services/database_service.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.initialize();
  final app = await builder();
  runApp(app);
}
