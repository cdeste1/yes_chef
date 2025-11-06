import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 225,
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/Photos/YesChefLogo.png',
            height: 135,
            fit: BoxFit.fitHeight,
          ),
          const SizedBox(width: 0),
          ///const Text(
          ///  "Yes Chef!",
          ///  style: TextStyle(
          ///    fontFamily: 'Montserrat',
          ///    fontWeight: FontWeight.bold,
          ///    fontSize: 22,
          ///    color: Colors.black87,
          ///    letterSpacing: 1.1,
          ///  ),
          ///),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}