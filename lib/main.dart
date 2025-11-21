import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'providers/medication_provider.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'pages/home_page_refactored.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase（如果需要联机功能，需要配置 Firebase）
  // await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MedicationProvider(
        notificationService: NotificationService(),
        firestoreService: FirestoreService(),
      ),
      child: MaterialApp(
        title: '专注达药效监测',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'SF Pro',
        ),
        home: const HomePage(),
      ),
    );
  }
}
