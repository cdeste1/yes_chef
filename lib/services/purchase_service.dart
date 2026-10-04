import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gates Cook Mode behind a single non-consumable purchase. One-time, not a
/// subscription — the feature has no ongoing per-user cost, so a recurring
/// charge wouldn't map to anything real and would add renewal/grace-period
/// complexity for no reason.
///
/// There's no backend: the App Store is the source of truth for entitlement,
/// and this just caches its answer locally (via shared_preferences) for a
/// fast, synchronous-feeling UI check on every screen build. The cache is
/// refreshed from the store's own purchase stream on launch and after every
/// purchase/restore, so a locally-edited flag can't fake entitlement for
/// long, and a legitimate reinstall recovers it via Restore Purchases.
///
/// The one-free-use allowance is tracked separately and is deliberately
/// local-only/unverified — it's a taste, not a security boundary. Clearing
/// app data resets it, which is an acceptable edge case for a $2.99 feature.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const String cookModeProductId = 'com.cdprojects.yeschef.cookmode';

  static const String _purchasedKey = 'cook_mode_purchased';
  static const String _freeUseUsedKey = 'cook_mode_free_use_used';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isAvailable = false;
  bool _isPurchased = false;
  bool _freeUseUsed = false;
  ProductDetails? _product;
  String? _pendingError;

  bool get isPurchased => _isPurchased;
  bool get freeUseUsed => _freeUseUsed;
  // Null until the store has actually responded — the paywall uses this to
  // show a loading state instead of a price that might not match what the
  // store will actually charge.
  ProductDetails? get product => _product;
  String? get pendingError => _pendingError;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPurchased = prefs.getBool(_purchasedKey) ?? false;
    _freeUseUsed = prefs.getBool(_freeUseUsedKey) ?? false;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      notifyListeners();
      return;
    }

    _purchaseSubscription =
        _iap.purchaseStream.listen(_handlePurchaseUpdates, onError: (_) {
      // Stream errors here are transient (network, store hiccup) — the UI
      // keeps whatever entitlement state it already has rather than
      // treating a dropped connection as "not purchased".
    });

    final response = await _iap.queryProductDetails({cookModeProductId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }
    notifyListeners();

    // Reconcile with the store's own record on every launch so a purchase
    // made on another device, or a restore that happened outside this
    // screen, is reflected without the user doing anything.
    await _iap.restorePurchases();
  }

  Future<void> markFreeUseUsed() async {
    if (_freeUseUsed) return;
    _freeUseUsed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_freeUseUsedKey, true);
    notifyListeners();
  }

  Future<void> buy() async {
    final product = _product;
    if (product == null) return;
    _pendingError = null;
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restore() async {
    _pendingError = null;
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.productID != cookModeProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grantEntitlement();
          break;
        case PurchaseStatus.error:
          _pendingError = purchase.error?.message ?? 'Purchase failed.';
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _grantEntitlement() async {
    _isPurchased = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_purchasedKey, true);
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
