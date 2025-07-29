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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters (make sure adapters are generated)
  Hive.registerAdapter(CropTaskAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(ProductTypeAdapter());
  Hive.registerAdapter(ListingTypeAdapter());
  Hive.registerAdapter(CropDataAdapter());
  Hive.registerAdapter(WateringScheduleAdapter());

  // Open Hive boxes
  await Hive.openBox<CropTask>(HiveService.taskBoxName);
  await Hive.openBox<User>(HiveService.userBoxName);
  await Hive.openBox<Product>(HiveService.productBoxName);
  await Hive.openBox<CropData>(HiveService.cropDataBoxName);
  await Hive.openBox(HiveService.settingsBoxName);

  // Optional: Migrate or update old tasks if needed
  final taskBox = Hive.box<CropTask>(HiveService.taskBoxName);
  for (var task in taskBox.values) {
    await task.save();
  }

  // Initialize HiveService (loads predefined crops if empty)
  final hiveService = HiveService();
  await hiveService.initializeCropData();

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.scheduleTaskNotifications();

  // Firebase Realtime Database reference
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
      home: SplashScreen(databaseRef: databaseRef),
    );
  }
}
