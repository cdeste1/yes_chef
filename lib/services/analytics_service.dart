import 'package:posthog_flutter/posthog_flutter.dart';

/// Thin wrapper around PostHog so call sites fire named events instead of
/// touching the SDK directly — keeps event names consolidated in one place
/// and makes it obvious at a glance which events exist across the app.
///
/// Autocapture (screen views, taps) is enabled via PosthogConfig in init(),
/// so this only needs to cover events autocapture can't infer — Cook Mode's
/// purchase funnel being the main one, since "a button was tapped" doesn't
/// tell you whether that tap resulted in a sale.
class AnalyticsService {
  AnalyticsService._();

  static Future<void> init() async {
    final config = PostHogConfig('phc_qeCdkTwbRZK4rUKGT8JHA5KbYXEg4d2cJ5AABLVYVYWA')
      ..host = 'https://us.i.posthog.com'
      ..captureApplicationLifecycleEvents = true;
    await Posthog().setup(config);
  }

  static void recipeViewed(String recipeName) {
    Posthog().capture(
      eventName: 'recipe_viewed',
      properties: {'recipe_name': recipeName},
    );
  }

  static void cookModeOpened(String recipeName, {required bool wasFreeUse}) {
    Posthog().capture(
      eventName: 'cook_mode_opened',
      properties: {'recipe_name': recipeName, 'was_free_use': wasFreeUse},
    );
  }

  static void cookModePaywallShown(String recipeName) {
    Posthog().capture(
      eventName: 'cook_mode_paywall_shown',
      properties: {'recipe_name': recipeName},
    );
  }

  static void cookModePurchased() {
    Posthog().capture(eventName: 'cook_mode_purchased');
  }

  static void cookModeRestored() {
    Posthog().capture(eventName: 'cook_mode_restored');
  }

  static void specialtyItemTapped(String itemName) {
    Posthog().capture(
      eventName: 'specialty_item_tapped',
      properties: {'item_name': itemName},
    );
  }
}
