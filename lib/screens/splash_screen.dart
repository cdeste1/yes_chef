import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'home_screen.dart'; // adjust path if needed

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
    _startUp();
  }

  // Wait for animation + small delay, and for the ATT prompt to be answered,
  // before moving on so the prompt is never covered by a route change.
  Future<void> _startUp() async {
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _requestTrackingPermission(),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // Without this, iOS zeroes out the IDFA and AdMob can only serve
  // non-personalized ads, which pay noticeably less. iOS silently drops the
  // request if the app isn't active yet (the case on a cold launch from
  // initState), so wait for the resumed lifecycle state plus a short delay
  // first. The Mobile Ads SDK is initialized only after the user answers,
  // so no ad/tracking SDK runs before the prompt. No-op on Android.
  Future<void> _requestTrackingPermission() async {
    if (!kIsWeb) {
      try {
        if (WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
          await _waitUntilResumed();
        }
        await Future.delayed(const Duration(milliseconds: 1000));
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (_) {
        // Never block launch on a tracking-prompt failure.
      }
      await MobileAds.instance.initialize();
    }
  }

  Future<void> _waitUntilResumed() {
    final completer = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(onResume: () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () {})
        .whenComplete(listener.dispose);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Photos/YesChefLogo_transparent.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 24),
              const Text(
                'Cook Bold. Elevate Your Dish.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}