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
              const Text(
                "Settings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
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
      expandedHeight: 225,   // full height when at top
      collapsedHeight: 60,   // compact height when scrolled
      pinned: true,          // stays visible at top
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: SafeArea(
          child: Stack(
            children: [
              // Logo fades/shrinks as you scroll
              Center(
                child: Image.asset(
                  'assets/Photos/YesChefLogo_transparent.png',
                  height: 135,
                  fit: BoxFit.fitHeight,
                ),
              ),
              // Settings button stays pinned top-right
              Positioned(
                right: 16,
                top: 16,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Color(0xFFF58220)),
                  onPressed: () => _openSettings(context),
                ),
              ),
            ],
          ),
        ),
        // Small logo shown in collapsed state
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Image.asset(
            'assets/Photos/YesChefLogo_transparent.png',
            height: 36,
            fit: BoxFit.fitHeight,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
      ),
      // Settings icon stays visible when collapsed
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFFF58220)),
          onPressed: () => _openSettings(context),
        ),
      ],
    );
  }
}