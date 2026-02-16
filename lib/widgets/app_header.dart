import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  static const String privacyUrl =
      "https://yourgithubusername.github.io/yourrepo/privacy.html";

  static const String termsUrl =
      "https://yourgithubusername.github.io/yourrepo/terms.html";

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
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,

      // ✅ Keep your logo exactly the same
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/Photos/YesChefLogo_transparent.png',
            height: 135,
            fit: BoxFit.fitHeight,
          ),
        ],
      ),

      // ✅ Add settings icon to right side
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () => _openSettings(context),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(225);
}
