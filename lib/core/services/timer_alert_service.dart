import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/services/local_notification_service.dart';

class TimerAlertService {
  TimerAlertService._();

  static final TimerAlertService instance = TimerAlertService._();

  final AudioPlayer _player = AudioPlayer(playerId: 'timer-alert');

  Future<void> playFinishedAlert() async {
    await LocalNotificationService.instance.showCookingDoneNotification();
    unawaited(_vibratePattern());
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setAudioContext(
        AudioContextConfig(
          route: AudioContextConfigRoute.system,
          focus: AudioContextConfigFocus.gain,
          respectSilence: false,
        ).build(),
      );
      await _player.stop();
      await _player.play(
        AssetSource('sounds/timer_done.wav'),
        volume: 1,
        mode: PlayerMode.mediaPlayer,
      );
    } catch (e, s) {
      LogManager.error(
        'Timer alert sound failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> stopFinishedAlert() async {
    try {
      await _player.stop();
    } catch (e, s) {
      LogManager.error(
        'Timer alert sound stop failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _vibratePattern() async {
    HapticFeedback.vibrate();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    HapticFeedback.heavyImpact();
  }
}
