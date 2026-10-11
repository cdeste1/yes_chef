import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/recipe_model.dart';

/// Builds the plain-text and PDF versions of a recipe for the paid
/// "copy / export" perk. Everything happens on-device — there's no server
/// involved, so entitlement is the same local PurchaseService check Cook
/// Mode uses.
class RecipeExportService {
  RecipeExportService._();

  static String _ingredientLine(Ingredient ing) =>
      '${ing.quantity.isNotEmpty ? '${ing.quantity} - ' : ''}'
      '${ing.item}'
      '${ing.note.isNotEmpty ? ' (${ing.note})' : ''}';

  // The bundled Roboto subset lacks a few glyphs that show up in recipe text
  // (arrows, vulgar fractions); fall back to ASCII so they don't print as
  // blank boxes.
  static const _glyphFallbacks = {
    '→': '->', '⅓': '1/3', '⅔': '2/3', '⅛': '1/8', '⅜': '3/8', '⅝': '5/8', '⅞': '7/8',
  };
  static String _s(String text) => _glyphFallbacks.entries
      .fold(text, (t, e) => t.replaceAll(e.key, e.value));

  static String toPlainText(Recipe recipe) {
    final b = StringBuffer(recipe.name);
    if (recipe.yieldInfo.isNotEmpty) b.write('\n${recipe.yieldInfo}');
    if (recipe.source.isNotEmpty) b.write('\nSource: ${recipe.source}');

    void section(Recipe r, {bool isSub = false}) {
      if (isSub) {
        b.write('\n\n${r.name.toUpperCase()}');
        if (r.yieldInfo.isNotEmpty) b.write('\nYield: ${r.yieldInfo}');
      }
      if (r.ingredients.isNotEmpty) {
        b.write('\n\nIngredients:');
        for (final ing in r.ingredients) {
          b.write('\n- ${_ingredientLine(ing)}');
        }
      }
      if (r.steps.isNotEmpty) {
        b.write('\n\nSteps:');
        for (var i = 0; i < r.steps.length; i++) {
          b.write('\n${i + 1}. ${r.steps[i].instruction}');
        }
      }
    }

    section(recipe);
    for (final sub in recipe.subRecipes) {
      section(sub, isSub: true);
    }
    b.write('\n\nYes Chef! ${recipe.shareUrl}');
    return b.toString();
  }

  static Future<Uint8List> buildPdf(Recipe recipe) async {
    Future<pw.Font> font(String name) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/$name'));
    final regular = await font('Roboto-Regular.ttf');
    final bold = await font('Roboto-Bold.ttf');
    final italic = await font('Roboto-Italic.ttf');

    // Black on white, no images or fills: this gets printed and read at
    // arm's length over a stove, so legibility and ink cost win over style.
    const body = 12.0;
    final base = pw.TextStyle(font: regular, fontSize: body, lineSpacing: 3);
    final heading = pw.TextStyle(font: bold, fontSize: 15);

    pw.Widget ingredientRow(Ingredient ing) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 9,
                height: 9,
                margin: const pw.EdgeInsets.only(top: 3, right: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
              ),
              pw.Expanded(child: pw.Text(_s(_ingredientLine(ing)))),
            ],
          ),
        );

    pw.Widget stepRow(int n, String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 24,
                child: pw.Text('$n.', style: pw.TextStyle(font: bold)),
              ),
              pw.Expanded(child: pw.Text(_s(text))),
            ],
          ),
        );

    List<pw.Widget> section(Recipe r, {bool isSub = false}) => [
          if (isSub) ...[
            pw.SizedBox(height: 18),
            pw.Text(_s(r.name), style: pw.TextStyle(font: bold, fontSize: 17)),
            if (r.yieldInfo.isNotEmpty)
              pw.Text(_s('Yield: ${r.yieldInfo}'),
                  style: pw.TextStyle(font: italic)),
          ],
          if (r.ingredients.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Ingredients', style: heading),
            pw.Divider(thickness: 1),
            ...r.ingredients.map(ingredientRow),
          ],
          if (r.steps.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Steps', style: heading),
            pw.Divider(thickness: 1),
            for (var i = 0; i < r.steps.length; i++)
              stepRow(i + 1, r.steps[i].instruction),
          ],
        ];

    final doc = pw.Document(title: recipe.name, author: 'Yes Chef!');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(48, 44, 48, 44),
        theme: pw.ThemeData.withFont(base: regular, bold: bold, italic: italic)
            .copyWith(defaultTextStyle: base),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Text(_s(recipe.name),
                style: pw.TextStyle(font: italic, fontSize: 10)),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Yes Chef!  ·  ${recipe.shareUrl}',
                style: pw.TextStyle(font: regular, fontSize: 9)),
            pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(font: regular, fontSize: 9)),
          ],
        ),
        build: (ctx) => [
          pw.Text('YES CHEF!',
              style: pw.TextStyle(font: bold, fontSize: 10, letterSpacing: 2)),
          pw.SizedBox(height: 8),
          pw.Text(_s(recipe.name), style: pw.TextStyle(font: bold, fontSize: 24)),
          if (recipe.yieldInfo.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(_s(recipe.yieldInfo), style: pw.TextStyle(font: italic)),
          ],
          if (recipe.source.isNotEmpty)
            pw.Text(_s('Source: ${recipe.source}'),
                style: pw.TextStyle(font: italic, fontSize: 10)),
          ...section(recipe),
          for (final sub in recipe.subRecipes) ...section(sub, isSub: true),
        ],
      ),
    );
    return doc.save();
  }

  /// Opens the iOS share sheet with the PDF attached (Save to Files, Print,
  /// AirDrop, etc. all come with it).
  static Future<void> sharePdf(Recipe recipe, {Rect? origin}) async {
    final bytes = await buildPdf(recipe);
    final fileName = '${recipe.slug}.pdf';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName)],
        fileNameOverrides: [fileName],
        subject: recipe.name,
        sharePositionOrigin: origin,
      ),
    );
  }
}
