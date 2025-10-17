import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/pages/login/complete_profile_page.dart';
import 'package:myapp/pages/main_features/maps/nearest_bank_map_screen.dart';
import 'package:myapp/pages/main_features/profile/account_info_screen.dart';
import 'package:myapp/pages/main_features/profile/address_screen.dart';
import 'package:myapp/pages/main_features/scan_qr.dart';
import 'package:myapp/pages/pickup/pickup_form_screen.dart';
import 'package:myapp/pages/pickup/pickup_location_screen.dart';
import 'package:myapp/pages/pickup/pickup_tracking_screen.dart';
import 'firebase_options.dart';

import 'pages/login/onboarding_screen.dart';
import 'pages/login/verify_email_page.dart';
import 'pages/login/auth_shell_page.dart';
import 'pages/main_features/app_shell.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TukarIn',
      theme: ThemeData(
        fontFamily: 'Figtree',
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF123524)),
        useMaterial3: true,
      ),
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth'      : (context) => const AuthShellPage(),
        '/verify': (context) => const VerifyEmailPage(),
        '/shell': (_) => const AppShell(),
        '/account': (_) => const AccountInfoScreen(),
        '/address': (_) => const AddressScreen(),
        '/complete-profile': (_) => const CompleteProfilePage(),
        '/scan-qr': (_) => const ScanQrPage(),
        '/pickup/location': (_) => const PickupLocationScreen(),
        '/pickup/form': (_) => const PickupFormScreen(),
        '/pickup/track': (_) => const PickupTrackingScreen(),
        '/maps/nearest': (_) => const NearestBankMapScreen(),
      },
    );
  }
}