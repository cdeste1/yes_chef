import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/splash_screen.dart';
import 'services/favorites_service.dart';
import 'services/purchase_service.dart';
import 'services/timer_notification_service.dart';
import 'widgets/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FavoritesService.init();
  await TimerNotificationService.initialize();
  // Not awaited — the store query can be slow/stalled on a bad connection,
  // and launch shouldn't block on it. Cook Mode's own gating check reads
  // whatever PurchaseService knows by the time the user actually taps it.
  PurchaseService.instance.init();

  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // Run the app immediately
  runApp(const MyApp());
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