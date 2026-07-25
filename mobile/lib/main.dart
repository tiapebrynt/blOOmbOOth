import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/history_model.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive untuk database lokal
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryModelAdapter());
  await Hive.openBox<HistoryModel>('photobooth_history');

  runApp(const PhotoboothApp());
}

class PhotoboothApp extends StatelessWidget {
  const PhotoboothApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photobooth App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeShell(), // 2. Ganti dari SplashScreen ke HomeScreen
    );
  }
}