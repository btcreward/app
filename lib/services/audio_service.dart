import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;

  /// Initialize audio service
  static Future<void> initialize() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _isInitialized = true;
    } catch (e) {
      // Ignore audio errors
    }
  }

  /// Play notification sound
  static Future<void> playNotificationSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Play custom notification sound
      await _audioPlayer.play(AssetSource('sounds/notification_alert.mp3'));
    } catch (e) {
      // Fallback to default system sound
      await _audioPlayer.play(AssetSource('sounds/earning_notification.mp3'));
    }
  }

  /// Play reward sound
  static Future<void> playRewardSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
    } catch (e) {
      // Ignore audio errors
    }
  }

  /// Play coin collection sound
  static Future<void> playCoinSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _audioPlayer.play(AssetSource('sounds/earning_notification.mp3'));
    } catch (e) {
      // Ignore audio errors
    }
  }

  /// Play error sound
  static Future<void> playErrorSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _audioPlayer.play(AssetSource('sounds/notification_alert.mp3'));
    } catch (e) {
      // Ignore audio errors
    }
  }

  /// Stop all sounds
  static Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      // Ignore audio errors
    }
  }

  /// Set volume (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      // Ignore audio errors
    }
  }

  /// Dispose audio player
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
    } catch (e) {
      // Ignore audio errors
    }
  }
}

