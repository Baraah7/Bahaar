import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Bahaar/services/sos_service.dart';

/// A persistent floating SOS button that requires a 3-second long-press
/// to activate, preventing accidental triggers.
///
/// Shows a circular progress ring during the hold, then opens a confirmation
/// dialog before dispatching the alert.
class SosButton extends StatefulWidget {
  /// Called when the user confirms SOS and the system begins sending.
  final Future<SosAlert> Function() onSosConfirmed;

  const SosButton({super.key, required this.onSosConfirmed});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  static const Duration _holdDuration = Duration(seconds: 3);

  late AnimationController _progressController;
  bool _holding = false;
  bool _sending = false;

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
    if (_sending) return;
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
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.sos, color: Colors.white, size: 48),
        title: const Text(
          'Send SOS Alert?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'This will send your GPS location and status to emergency services.\n\nOnly use in a genuine emergency.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'SEND SOS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dispatchSos();
    }
  }

  Future<void> _dispatchSos() async {
    setState(() => _sending = true);

    // Show sending indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Sending SOS alert...'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 30),
        ),
      );
    }

    final alert = await widget.onSosConfirmed();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _sending = false);

    if (alert.status == SosStatus.sent) {
      _showResultDialog(success: true);
    } else {
      _showResultDialog(success: false);
    }
  }

  void _showResultDialog({required bool success}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          success ? Icons.check_circle : Icons.error,
          color: success ? Colors.green : Colors.red,
          size: 48,
        ),
        title: Text(success ? 'SOS Sent' : 'SOS Failed'),
        content: Text(
          success
              ? 'Your emergency alert has been transmitted with your GPS location. Help is on the way.'
              : 'Failed to send SOS alert. Please try again or use radio channel 16.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                color: _sending ? Colors.orange : Colors.red.shade700,
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
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sos, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
