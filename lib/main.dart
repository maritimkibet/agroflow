import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/crop_task.dart';
import 'models/user.dart';
import 'models/product.dart';
import 'models/crop_data.dart';

import 'services/hive_service.dart';
import 'services/notification_service.dart';

import 'screens/splash_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'wrappers/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();

  Hive.registerAdapter(CropTaskAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(ProductTypeAdapter());
  Hive.registerAdapter(ListingTypeAdapter());
  Hive.registerAdapter(CropDataAdapter());
  Hive.registerAdapter(WateringScheduleAdapter());

  await Hive.openBox<CropTask>(HiveService.taskBoxName);
  await Hive.openBox<User>(HiveService.userBoxName);
  await Hive.openBox<Product>(HiveService.productBoxName);
  await Hive.openBox<CropData>(HiveService.cropDataBoxName);
  await Hive.openBox(HiveService.settingsBoxName);

  final taskBox = Hive.box<CropTask>(HiveService.taskBoxName);
  for (var task in taskBox.values) {
    await task.save();
  }

  final hiveService = HiveService();
  await hiveService.initializeCropData();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.scheduleTaskNotifications();

  final databaseRef = FirebaseDatabase.instance.ref();

  runApp(MyApp(
    notificationService: notificationService,
    databaseRef: databaseRef,
  ));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;
  final DatabaseReference databaseRef;

  const MyApp({
    super.key,
    required this.notificationService,
    required this.databaseRef,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green.shade700,
          secondary: Colors.brown.shade600,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(databaseRef: databaseRef),
        '/auth': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
