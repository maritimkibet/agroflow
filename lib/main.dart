import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/currency_selection_screen.dart';
import 'screens/marketplace/marketplace_screen.dart';
import 'screens/marketplace/add_product_screen.dart';
import 'screens/marketplace/product_detail_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/referral_screen.dart';
import 'screens/crop_doctor_screen.dart';
import 'screens/legal/terms_conditions_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/expense_tracker_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'wrappers/auth_wrapper.dart';
import 'services/hive_service.dart';
import 'models/product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await Hive.initFlutter();
    await HiveService().initializeHive();
  } catch (e) {
    // Continue without Firebase if initialization fails
    await Hive.initFlutter();
    await HiveService().initializeHive();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/currency_selection': (context) => const CurrencySelectionScreen(),
        '/marketplace': (context) => const MarketplaceScreen(),
        '/add_product': (context) => const AddProductScreen(),
        '/community': (context) => const CommunityScreen(),
        '/admin_login': (context) => const AdminLoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/achievements': (context) => const AchievementsScreen(),
        '/referral': (context) => const ReferralScreen(),
        '/crop_doctor': (context) => const CropDoctorScreen(),
        '/terms_conditions': (context) => const TermsConditionsScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/ai_assistant': (context) => const AIAssistantScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/expense_tracker': (context) => const ExpenseTrackerScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        switch (settings.name) {
          case '/product-detail':
            final product = settings.arguments as Product?;
            if (product != null) {
              return MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              );
            }
            break;
          case '/add-product':
            final product = settings.arguments as Product?;
            return MaterialPageRoute(
              builder: (context) => AddProductScreen(existingProduct: product),
            );
        }
        return null;
      },
    );
  }
}