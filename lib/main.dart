import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/crop_task.dart';
import 'models/user.dart';
import 'models/product.dart';
import 'models/crop_data.dart';
import 'models/automation_response.dart';
import 'models/admin_user.dart';

import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/achievement_service.dart';
import 'services/referral_service.dart';
import 'services/growth_analytics_service.dart';
import 'services/error_service.dart';

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
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/marketplace/add_product_screen.dart';
import 'screens/marketplace/marketplace_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/calendar_screen.dart';

import 'screens/community/community_screen.dart';
import 'screens/expense_tracker_screen.dart';
import 'screens/legal/terms_conditions_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'wrappers/auth_wrapper.dart';
import 'services/platform_service.dart';
import 'services/admin_setup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize error handling first
    ErrorService.initialize();

    // Initialize critical services only
    await Firebase.initializeApp();
    await Hive.initFlutter();

    // Register adapters (fast operation)
    _registerHiveAdapters();

    // Open essential boxes only for startup
    await _openEssentialBoxes();

    final databaseRef = FirebaseDatabase.instance.ref();

    runApp(MyApp(databaseRef: databaseRef));

    // Initialize remaining services in background after app starts
    _initializeBackgroundServices();
  } catch (e) {
    debugPrint('App initialization error: $e');
    // Still run the app with minimal functionality
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('App initialization failed'),
                const SizedBox(height: 8),
                Text('Error: $e'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _registerHiveAdapters() {
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
  Hive.registerAdapter(AdminRoleAdapter());
  Hive.registerAdapter(AdminUserAdapter());
  Hive.registerAdapter(SupportTicketAdapter());
  Hive.registerAdapter(TicketPriorityAdapter());
  Hive.registerAdapter(TicketStatusAdapter());
  Hive.registerAdapter(UserActivityAdapter());
}

Future<void> _openEssentialBoxes() async {
  try {
    await Future.wait([
      Hive.openBox<User>(HiveService.userBoxName),
      Hive.openBox(HiveService.settingsBoxName),
    ]);
  } catch (e) {
    debugPrint('Error opening essential boxes: $e');
    // Continue without local storage if needed
  }
}

void _initializeBackgroundServices() async {
  try {
    // Open remaining boxes
    await _openRemainingBoxes();

    // Initialize services in background
    await _initializeServices();

    debugPrint('Background services initialized successfully');
  } catch (e) {
    debugPrint('Background initialization error: $e');
    // App continues to work without background services
  }
}

Future<void> _openRemainingBoxes() async {
  try {
    await Future.wait([
      Hive.openBox<CropTask>(HiveService.taskBoxName),
      Hive.openBox<Product>(HiveService.productBoxName),
      Hive.openBox<CropData>(HiveService.cropDataBoxName),
    ]);
  } catch (e) {
    debugPrint('Error opening remaining boxes: $e');
  }
}

Future<void> _initializeServices() async {
  try {
    final hiveService = HiveService();
    final notificationService = NotificationService();
    final achievementService = AchievementService();
    final referralService = ReferralService();
    final analyticsService = GrowthAnalyticsService();

    // Initialize core services
    await Future.wait([
      hiveService.initializeCropData(),
      notificationService.initialize(),
      achievementService.initialize(),
      referralService.initialize(),
    ]);

    // Track app open for growth analytics
    await analyticsService.trackAppOpen();

    // Initialize admin accounts (critical for production)
    final adminSetupService = AdminSetupService();
    await adminSetupService.initializeDefaultAdmins();

    // Schedule notifications after initialization
    await notificationService.scheduleTaskNotifications();

    // Save existing tasks (if any) - non-blocking
    _saveExistingTasks();
  } catch (e) {
    debugPrint('Error initializing services: $e');
  }
}

void _saveExistingTasks() {
  try {
    if (Hive.isBoxOpen(HiveService.taskBoxName)) {
      final taskBox = Hive.box<CropTask>(HiveService.taskBoxName);
      for (var task in taskBox.values) {
        task.save(); // Non-blocking save
      }
    }
  } catch (e) {
    debugPrint('Error saving existing tasks: $e');
  }
}

class MyApp extends StatelessWidget {
  final DatabaseReference databaseRef;

  const MyApp({super.key, required this.databaseRef});

  @override
  Widget build(BuildContext context) {
    final platformService = PlatformService.instance;
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        primary: Colors.green.shade700,
        secondary: Colors.green.shade400,
        surface: Colors.grey.shade50,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );

    return MaterialApp(
      title: platformService.getAppTitle(),
      debugShowCheckedModeBanner: false,
      theme: platformService
          .getPlatformTheme(baseTheme)
          .copyWith(
            scaffoldBackgroundColor:
                Colors.green.shade50, // Prevent dark screen
          ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle all routes through a single generator for better control
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => SplashScreen(databaseRef: databaseRef),
            );
          case '/auth':
            return MaterialPageRoute(builder: (context) => const AuthWrapper());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(
              builder: (context) => const RegisterScreen(),
            );
          case '/profile_setup':
            return MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(),
            );
          case '/onboarding':
            return MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            );
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/referral':
            return MaterialPageRoute(
              builder: (context) => const ReferralScreen(),
            );
          case '/achievements':
            return MaterialPageRoute(
              builder: (context) => const AchievementsScreen(),
            );
          case '/analytics':
            return MaterialPageRoute(
              builder: (context) => const AnalyticsScreen(),
            );
          case '/crop_doctor':
            return MaterialPageRoute(
              builder: (context) => const CropDoctorScreen(),
            );
          case '/traceability':
            return MaterialPageRoute(
              builder: (context) => const TraceabilityScreen(),
            );
          case '/climate_adaptation':
            return MaterialPageRoute(
              builder: (context) => const ClimateAdaptationScreen(),
            );
          case '/social_media_hub':
            return MaterialPageRoute(
              builder: (context) => const SocialMediaHubScreen(),
            );
          case '/automation':
            return MaterialPageRoute(
              builder: (context) => const AutomationScreen(),
            );
          case '/admin_login':
            return MaterialPageRoute(
              builder: (context) => const AdminLoginScreen(),
            );
          case '/admin_dashboard':
            return MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            );
          case '/add_product':
            return MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            );
          case '/marketplace':
            return MaterialPageRoute(
              builder: (context) => const MarketplaceScreen(),
            );
          case '/ai_assistant':
            return MaterialPageRoute(
              builder: (context) => const AIAssistantScreen(),
            );
          case '/calendar':
            return MaterialPageRoute(
              builder: (context) => const CalendarScreen(),
            );

          case '/community':
            return MaterialPageRoute(
              builder: (context) => const CommunityScreen(),
            );
          case '/expense_tracker':
            return MaterialPageRoute(
              builder: (context) => const ExpenseTrackerScreen(),
            );
          case '/terms_conditions':
            return MaterialPageRoute(
              builder: (context) => const TermsConditionsScreen(),
            );
          case '/privacy_policy':
            return MaterialPageRoute(
              builder: (context) => const PrivacyPolicyScreen(),
            );
          default:
            // Fallback to home for unknown routes
            return MaterialPageRoute(builder: (context) => const HomeScreen());
        }
      },
    );
  }
}
