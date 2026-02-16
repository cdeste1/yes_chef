import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
  return AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: 225,
    elevation: 0,
    backgroundColor: Colors.transparent,

    // Remove title & actions entirely
    title: null,
    actions: null,

    flexibleSpace: SafeArea(
      child: Stack(
        children: [
          // ✅ Perfectly centered logo
          Center(
            child: Image.asset(
              'assets/Photos/YesChefLogo_transparent.png',
              height: 135,
              fit: BoxFit.fitHeight,
            ),
          ),

          // ✅ Settings button pinned to right
          Positioned(
            right: 16,
            top: 16,
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                color: Color(0xFFF58220),
              ),
              onPressed: () => _openSettings(context),
            ),
          ),
        ],
      ),
    ),
  );
}

@override
Size get preferredSize => const Size.fromHeight(225);
}
