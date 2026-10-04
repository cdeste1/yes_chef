import 'package:flutter/material.dart';
import '../services/purchase_service.dart';

/// Shown instead of Cook Mode once the one free use is spent and the user
/// hasn't bought the unlock. Not a hard dead end — Back always works, this
/// is the only screen standing between "no Cook Mode" and "Cook Mode", so
/// it carries the actual sales pitch rather than a generic "upgrade" screen.
class CookModePaywallScreen extends StatefulWidget {
  const CookModePaywallScreen({super.key});

  @override
  State<CookModePaywallScreen> createState() => _CookModePaywallScreenState();
}

class _CookModePaywallScreenState extends State<CookModePaywallScreen> {
  static const Color _flame = Color(0xFFF58220);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    PurchaseService.instance.addListener(_onPurchaseChanged);
  }

  @override
  void dispose() {
    PurchaseService.instance.removeListener(_onPurchaseChanged);
    super.dispose();
  }

  void _onPurchaseChanged() {
    if (!mounted) return;
    setState(() {});
    if (PurchaseService.instance.isPurchased) {
      // Purchase/restore landed — hand control back to whatever opened the
      // paywall (the Cook Mode button re-checks entitlement on its own).
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    try {
      await PurchaseService.instance.buy();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await PurchaseService.instance.restore();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _bullet(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _flame, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = PurchaseService.instance.product;
    final error = PurchaseService.instance.pendingError;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Cook Mode'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plating. Yes Chef. Send it.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Cook Mode runs the pass for you — one step at a time, "
                "hands-free, exactly when you need it.",
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 20),
              _bullet(
                Icons.mic_none,
                'Call it, we\'ll do it.',
                '"Next." "Back." "Timer, five minutes." No wiping your hands '
                    'on your apron to tap a screen.',
              ),
              _bullet(
                Icons.record_voice_over_outlined,
                'It talks you through it.',
                'Every step read aloud, eyes on the pan, not the phone.',
              ),
              _bullet(
                Icons.timer_outlined,
                'Nothing burns on your watch.',
                'Voice-set timers that keep running even if you walk away.',
              ),
              _bullet(
                Icons.restaurant_menu,
                'Knows a sauce from the whole dish.',
                'Multi-component recipes get a clear "now plating" moment — '
                    'no getting lost between the ganache and the cake.',
              ),
              const SizedBox(height: 24),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(error,
                      style: const TextStyle(color: Color(0xFFE54B4B), fontSize: 13)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_busy || product == null) ? null : _buy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _flame,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          product == null
                              ? 'Loading price…'
                              : 'Unlock Cook Mode — ${product.price}, once, forever',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _restore,
                  child: const Text('Restore Purchase',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
