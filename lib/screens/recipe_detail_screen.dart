import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipe_model.dart';
import '../services/favorites_service.dart';
import '../services/purchase_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/nugget_promo_banner.dart';
import 'cook_mode_paywall_screen.dart';
import 'cook_mode_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  // Cook Mode is gated behind one free use ever (across all recipes, not
  // per-recipe) and then a single non-consumable purchase. The free use is
  // consumed the moment Cook Mode is entered, not on exit — so a user who
  // backs out immediately has still spent it, same as a free sample you
  // took a bite of.
  Future<void> _openCookMode(BuildContext context, Recipe recipe) async {
    final purchases = PurchaseService.instance;

    if (!purchases.isPurchased && purchases.freeUseUsed) {
      final unlocked = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const CookModePaywallScreen()),
      );
      if (unlocked != true || !purchases.isPurchased) return;
    } else if (!purchases.isPurchased) {
      await purchases.markFreeUseUsed();
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CookModeScreen(recipe: recipe)),
    );
  }

  void _shareRecipe(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: '${recipe.name}\n${recipe.shareUrl}',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(recipe.name),
        ),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesService.favoritesNotifier,
            builder: (context, favoriteSlugs, _) {
              final isFavorite = favoriteSlugs.contains(recipe.slug);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? const Color(0xFFF58220) : null,
                ),
                tooltip: isFavorite ? 'Remove from Saved Recipes' : 'Save recipe',
                onPressed: () => FavoritesService.toggleFavorite(recipe.slug),
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share recipe',
              onPressed: () => _shareRecipe(context),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Recipe Info =====
            if (recipe.imageUrl.isNotEmpty)
                 Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: recipe.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 300,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Text('Image failed to load'),
                      ),
                    ),
                  ),
                ),
            if (recipe.source.isNotEmpty)
              Text(
                'Source: ${recipe.source}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            if (recipe.chef.isNotEmpty)
              Text(
                'Inspiring Chef: ${recipe.chef}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            if (recipe.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                recipe.description,
                style: const TextStyle(fontSize: 16),
              ),
              
            ],
            if (recipe.yieldInfo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                recipe.yieldInfo,
                style: const TextStyle(fontSize: 16),
              ),
              
            ],

            const SizedBox(height: 16),
            const Divider(thickness: 1),

            // ===== Ingredients =====
            if (recipe.ingredients.isNotEmpty) ...[
              const Text('Ingredients:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 6),
              ...recipe.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '• '
                      '${ing.quantity.isNotEmpty ? '${ing.quantity} - ' : ''}'
                      '${ing.item}'
                      '${ing.note.isNotEmpty ? ' (${ing.note})' : ''}',
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  )),
            ],

            const SizedBox(height: 16),
            const Divider(thickness: 1),

            if (recipe.specialtools.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              const Text(
                'Speciality Items:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: recipe.specialtools
                    .map((tool) => _SpecialToolChip(tool: tool))
                    .toList(),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Yes Chef! may earn a commission from qualifying purchases made through links in this app.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            // ===== Sommelier’s Recommendation =====
            if (recipe.winePairings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2B2B2B),
                      const Color(0xFF1A1A1A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.wine_bar, color: Color(0xFFF58220)),
                        SizedBox(width: 8),
                        Text(
                          "Sommelier’s Recommendation",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ...recipe.winePairings.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "• ${w.name}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (w.notes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 14, top: 4),
                                child: Text(
                                  w.notes,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            if (w.link.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 14, top: 4),
                                child: GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.parse(w.link);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: const Text(
                                    'Shop this wine',
                                    style: TextStyle(
                                      color: Color(0xFFF58220),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],



            // ===== Steps =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Steps:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                if (recipe.steps.isNotEmpty ||
                    recipe.subRecipes.any((sub) => sub.steps.isNotEmpty))
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restaurant_menu, size: 18),
                    label: const Text('Cook Mode'),
                    onPressed: () => _openCookMode(context, recipe),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ...recipe.steps.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '${entry.key + 1}. ${entry.value.instruction}',
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ),

            const SizedBox(height: 16),

            // ===== Sub-Recipes =====
            if (recipe.subRecipes.isNotEmpty) ...[
              const Divider(thickness: 1),
              const Text('Sub-Recipes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ...recipe.subRecipes.map((sub) => _buildSubRecipe(sub)),
            ],

            const SizedBox(height: 24),

            // Ad banner + house ad — once per recipe page, not per sub-recipe
            const NuggetPromoBanner(),
            const AdBanner(),

            const SizedBox(height: 16),

            // ===== ⬇️ Added collapsible disclaimer =====
            const RecipeDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubRecipe(Recipe sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sub.name,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (sub.yieldInfo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 6.0),
              child: Text('Yield: ${sub.yieldInfo}',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),

          const Text('Ingredients:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          ...sub.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Text(
                  '• '
                  '${ing.quantity.isNotEmpty ? '${ing.quantity} - ' : ''}'
                  '${ing.item}'
                  '${ing.note.isNotEmpty ? ' (${ing.note})' : ''}',
                  style: const TextStyle(fontSize: 15),
                ),
              )),
          const SizedBox(height: 8),

          const Text('Steps:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          ...sub.steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '${entry.key + 1}. ${entry.value.instruction}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// A compact, tappable "product chip" for a recipe's specialty items —
/// replaces a repeated "Need it? Click here to start cooking" sentence per
/// item, which read as spammy once a recipe listed several tools. Items
/// with no affiliate link still render (as plain, non-tappable chips) so a
/// specialty item mentioned without a link isn't silently dropped.
class _SpecialToolChip extends StatelessWidget {
  final SpecialTools tool;

  const _SpecialToolChip({required this.tool});

  @override
  Widget build(BuildContext context) {
    final hasLink = tool.link.isNotEmpty;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasLink
            ? const Color(0xFFF58220).withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasLink
              ? const Color(0xFFF58220).withValues(alpha: 0.6)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tool.item,
            style: TextStyle(
              fontSize: 14,
              color: hasLink
                  ? const Color(0xFFF58220)
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: hasLink ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (hasLink) ...[
            const SizedBox(width: 6),
            const Icon(Icons.shopping_bag_outlined,
                size: 15, color: Color(0xFFF58220)),
          ],
        ],
      ),
    );

    if (!hasLink) return chip;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final uri = Uri.parse(tool.link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: chip,
    );
  }
}

//
// === Collapsible Disclaimer Widget ===
//
class RecipeDisclaimer extends StatelessWidget {
  const RecipeDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: Colors.grey[600],
        collapsedIconColor: Colors.grey[600],
        title: Text(
          "More Info",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
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
          ),
        ],
      ),
    );
  }
}