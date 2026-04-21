import 'package:bahaar/l10n/map/map_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  static const Duration _holdDuration = Duration(seconds: 3);

  late AnimationController _progressController;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _holdDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _holding) {
          _onHoldComplete();
        }
      });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _onPressStart() {
    setState(() => _holding = true);
    _progressController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _onPressEnd() {
    if (!_holding) return;
    setState(() => _holding = false);
    _progressController.reverse();
  }

  Future<void> _onHoldComplete() async {
    setState(() {
      _holding = false;
      _progressController.value = 0;
    });
    HapticFeedback.heavyImpact();
    await _showConfirmationDialog();
  }

  Future<void> _showConfirmationDialog() async {
    final l10n = MapLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.sos, color: Colors.white, size: 48),
        title: Text(
          l10n.sosSendAlert,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.sosDialogBody,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.sosSend,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _callEmergency();
    }
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:17700000');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _onPressStart(),
      onLongPressEnd: (_) => _onPressEnd(),
      onLongPressCancel: _onPressEnd,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring
            AnimatedBuilder(
              animation: _progressController,
              builder: (_, __) => CircularProgressIndicator(
                value: _progressController.value,
                strokeWidth: 4,
                backgroundColor: Colors.red.withValues(alpha: 0.25),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            // SOS button core
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.sos, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
