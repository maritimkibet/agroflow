import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/crop_task.dart';
import 'models/user.dart';
import 'models/product.dart';
import 'models/crop_data.dart';
import 'models/automation_response.dart';

import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/achievement_service.dart';
import 'services/referral_service.dart';
import 'services/growth_analytics_service.dart';

import 'screens/splash_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/referral_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/crop_doctor_screen.dart';
import 'screens/traceability_screen.dart';
import 'screens/climate_adaptation_screen.dart';
import 'screens/social_media_hub_screen.dart';
import 'screens/automation_screen.dart';
import 'wrappers/auth_wrapper.dart';
import 'services/platform_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize critical services only
  await Firebase.initializeApp();
  await Hive.initFlutter();

  // Register adapters (fast operation)
  Hive.registerAdapter(CropTaskAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(ProductTypeAdapter());
  Hive.registerAdapter(ListingTypeAdapter());
  Hive.registerAdapter(CropDataAdapter());
  Hive.registerAdapter(WateringScheduleAdapter());
  Hive.registerAdapter(AutomationResponseAdapter());
  Hive.registerAdapter(PricingSuggestionAdapter());
  Hive.registerAdapter(SmartScheduleSuggestionAdapter());

  // Open essential boxes only
  await Future.wait([
    Hive.openBox<User>(HiveService.userBoxName),
    Hive.openBox(HiveService.settingsBoxName),
  ]);

  final databaseRef = FirebaseDatabase.instance.ref();

  runApp(
    MyApp(databaseRef: databaseRef),
  );

  // Initialize remaining services in background after app starts
  _initializeBackgroundServices();
}

void _initializeBackgroundServices() async {
  try {
    // Open remaining boxes
    await Future.wait([
      Hive.openBox<CropTask>(HiveService.taskBoxName),
      Hive.openBox<Product>(HiveService.productBoxName),
      Hive.openBox<CropData>(HiveService.cropDataBoxName),
    ]);

    // Initialize services in background
    final hiveService = HiveService();
    final notificationService = NotificationService();
    final achievementService = AchievementService();
    final referralService = ReferralService();
    final analyticsService = GrowthAnalyticsService();
    
    await Future.wait([
      hiveService.initializeCropData(),
      notificationService.initialize(),
      achievementService.initialize(),
      referralService.initialize(),
    ]);
    
    // Track app open for growth analytics
    await analyticsService.trackAppOpen();

    // Schedule notifications after initialization
    await notificationService.scheduleTaskNotifications();

    // Save existing tasks (if any)
    final taskBox = Hive.box<CropTask>(HiveService.taskBoxName);
    for (var task in taskBox.values) {
      task.save(); // Remove await to make it non-blocking
    }
  } catch (e) {
    debugPrint('Background initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  final DatabaseReference databaseRef;

  const MyApp({
    super.key,
    required this.databaseRef,
  });

  @override
  Widget build(BuildContext context) {
    final platformService = PlatformService.instance;
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        primary: Colors.green.shade700,
        secondary: Colors.brown.shade600,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: platformService.getAppTitle(),
      debugShowCheckedModeBanner: false,
      theme: platformService.getPlatformTheme(baseTheme).copyWith(
        scaffoldBackgroundColor: Colors.green.shade50, // Prevent dark screen
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(databaseRef: databaseRef),
        '/auth': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/referral': (context) => const ReferralScreen(),
        '/achievements': (context) => const AchievementsScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/crop_doctor': (context) => const CropDoctorScreen(),
        '/traceability': (context) => const TraceabilityScreen(),
        '/climate_adaptation': (context) => const ClimateAdaptationScreen(),
        '/social_media_hub': (context) => const SocialMediaHubScreen(),
        '/automation': (context) => const AutomationScreen(),
      },
    );
  }
}
