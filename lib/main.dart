import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/splash_screen.dart';
import 'widgets/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app immediately
  runApp(const MyApp());

  // Initialize ads *after* the first frame
  MobileAds.instance.initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yes Chef!',
      debugShowCheckedModeBanner: false,
      theme: YesChefTheme.buildTheme(),
      home: const SplashScreen(),
    );
  }
}

