import 'package:flutter/services.dart';
import 'game_storage.dart';

class AudioManager {
  static void playTileSelect() {
    if (GameStorage.getHapticEnabled()) {
      HapticFeedback.selectionClick();
    }
  }

  static void playWordMatch() {
    if (GameStorage.getSoundEnabled()) {
      SystemSound.play(SystemSoundType.click);
    }
    if (GameStorage.getHapticEnabled()) {
      HapticFeedback.mediumImpact();
    }
  }

  static void playExtraWord() {
    if (GameStorage.getSoundEnabled()) {
      SystemSound.play(SystemSoundType.click);
    }
    if (GameStorage.getHapticEnabled()) {
      HapticFeedback.lightImpact();
    }
  }

  static void playObstacleUnlock() {
    if (GameStorage.getHapticEnabled()) {
      HapticFeedback.heavyImpact();
    }
  }

  static void playVictory() {
    if (GameStorage.getHapticEnabled()) {
      HapticFeedback.vibrate();
    }
  }

  static void playInvalid() {
    if (GameStorage.getHapticEnabled()) {
      HapticFeedback.lightImpact();
    }
  }
}
