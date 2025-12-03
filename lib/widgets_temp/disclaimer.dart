import 'package:flutter/material.dart';

class RecipeDisclaimer extends StatelessWidget {
  const RecipeDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Theme(
        // Make the tile subtle and minimal
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 4.0),
          title: Text(
            "More Info",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          iconColor: Colors.grey[600],
          collapsedIconColor: Colors.grey[600],

          children: [
            Text(
              "Disclaimer:\n"
              "The information and recipes provided within this application are intended for "
              "general informational and personal use only. Yes Chef makes no guarantees "
              "regarding accuracy, ingredient safety, or cooking outcomes. Users are responsible "
              "for checking allergen information, food safety temperatures, and proper handling "
              "of all ingredients. By using this app, you acknowledge that Yes Chef and its "
              "contributors are not liable for any adverse reactions, injuries, or results "
              "that may occur.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
