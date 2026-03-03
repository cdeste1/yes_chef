import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  static const String privacyUrl =
      "https://cdeste1.github.io/yes_chef/legal/privacy.html";
  static const String termsUrl =
      "https://cdeste1.github.io/yes_chef/legal/terms.html";

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Settings",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text("Privacy Policy"),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _launchURL(privacyUrl),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text("Terms of Service"),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _launchURL(termsUrl),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 225,
      collapsedHeight: 75,
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      forceMaterialTransparency: true,
      // ✅ No actions: here — settings is handled inside LayoutBuilder
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          const double minHeight = 75;
          const double maxHeight = 225;
          final double t = ((maxHeight - constraints.maxHeight) /
                  (maxHeight - minHeight))
              .clamp(0.0, 1.0);

          // Logo shrinks from 225 down to 135 as you scroll
          final double logoSize = 225 - (90 * t);

          // Settings icon shrinks from 28 to 22 and fades slightly
          final double iconSize = 28 - (6 * t);

          // Icon moves from top-right corner inward as bar collapses
          final double iconTop = 16 - (4 * t);
          final double iconRight = 8.0;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              children: [
                // ✅ Logo — centered, shrinks as you scroll
                Center(
                  child: Image.asset(
                    'assets/Photos/YesChefLogo_transparent.png',
                    height: logoSize,
                    fit: BoxFit.fitHeight,
                  ),
                ),

                // ✅ Settings icon — always visible, scales with collapse
                Positioned(
                  top: iconTop,
                  right: iconRight,
                  child: SafeArea(
                    child: IconButton(
                      iconSize: iconSize,
                      icon: const Icon(Icons.settings,
                          color: Color(0xFFF58220)),
                      onPressed: () => _openSettings(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}