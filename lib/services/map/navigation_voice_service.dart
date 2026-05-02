import 'dart:developer';
import 'package:flutter_tts/flutter_tts.dart';

/// Provides spoken turn-by-turn navigation instructions.
///
/// Call [init] once before use, [speak] to announce instructions, and
/// [dispose] when navigation ends.
class NavigationVoiceService {
  final FlutterTts _tts = FlutterTts();

  // Tracks the last spoken text so we never repeat the same instruction.
  String? _lastSpoken;

  // Tracks whether a 200 m approach announcement has been made for a waypoint.
  String? _approachAnnouncedFor;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
      log('NavigationVoiceService: initialized');
    } catch (e) {
      log('NavigationVoiceService: init failed: $e');
    }
  }

  /// Speaks [text] unless it is identical to the last announcement.
  Future<void> speak(String text) async {
    if (!_initialized) await init();
    if (text == _lastSpoken) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
      _lastSpoken = text;
      log('NavigationVoiceService: "$text"');
    } catch (e) {
      log('NavigationVoiceService: speak failed: $e');
    }
  }

  /// Announce an approaching waypoint when within [thresholdMeters].
  /// Only fires once per waypoint id.
  Future<void> announceApproach(
      String waypointId, String instruction, double distanceMeters,
      {double thresholdMeters = 200}) async {
    if (distanceMeters > thresholdMeters) return;
    if (_approachAnnouncedFor == waypointId) return;
    _approachAnnouncedFor = waypointId;
    final distText = distanceMeters >= 100
        ? 'In ${(distanceMeters / 100).round() * 100} metres'
        : 'In ${distanceMeters.round()} metres';
    await speak('$distText, $instruction');
  }

  /// Resets the approach tracker so the next waypoint can be announced.
  void resetApproach() {
    _approachAnnouncedFor = null;
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    stop();
  }
}
