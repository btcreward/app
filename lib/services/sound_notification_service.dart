import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SoundNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Initialize the service
  static Future<void> initialize() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap - navigate to notification screen
          // Navigation will be handled by the main app's notification listener
        },
      );

      // Create notification channels
      await _createNotificationChannels();
    } catch (e) {
      // Ignore notification errors
    }
  }

  // Create notification channels
  static Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Mining notification channel
      const miningChannel = AndroidNotificationChannel(
        'mining_channel',
        'Mining Status',
        description: 'Shows current mining stats and status',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // Reward notification channel
      const rewardChannel = AndroidNotificationChannel(
        'reward_channel',
        'Rewards',
        description: 'Notifications for rewards and earnings',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // Redemption notification channel
      const redemptionChannel = AndroidNotificationChannel(
        'redemption_channel',
        'Redemptions',
        description: 'Notifications for redemptions',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // Alert notification channel
      const alertChannel = AndroidNotificationChannel(
        'alert_channel',
        'Alerts',
        description: 'General app alerts and notifications',
        importance: Importance.low,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(miningChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(rewardChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(redemptionChannel);

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(alertChannel);
    }
  }

  // Play notification sound
  static Future<void> playNotificationSound(String soundType) async {
    try {
      String soundPath;
      switch (soundType) {
        case 'mining':
          soundPath = 'sounds/mining_notification.mp3';
          break;
        case 'reward':
          soundPath = 'sounds/reward_notification.mp3';
          break;
        case 'redemption':
          soundPath = 'sounds/withdrawal_notification.mp3';
          break;
        case 'alert':
          soundPath = 'sounds/notification_alert.mp3';
          break;
        case 'earning':
          soundPath = 'sounds/earning_notification.mp3';
          break;
        case 'success_chime':
          soundPath = 'sounds/success_chime.mp3';
          break;
        default:
          soundPath = 'sounds/notification_alert.mp3';
      }

      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Ignore notification errors
    }
  }

  // Play earning notification sound specifically
  static Future<void> playEarningSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/earning_notification.mp3'));
    } catch (e) {
      // Fallback to success chime
      try {
        await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
      } catch (e2) {
        // Ignore fallback errors
      }
    }
  }

  // Play sci-fi power up sound
  static Future<void> playSciFiPowerUpSound() async {
    try {
      // Use a different existing sound for power up effect
      await _audioPlayer.play(AssetSource('sounds/earning_notification.mp3'));
    } catch (e) {
      // Fallback to success chime
      try {
        await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
      } catch (e2) {
        // Ignore fallback errors
      }
    }
  }

  // Play sci-fi achievement sound
  static Future<void> playSciFiAchievementSound() async {
    try {
      // Use notification alert for achievement sound (more dramatic)
      await _audioPlayer.play(AssetSource('sounds/notification_alert.mp3'));
    } catch (e) {
      // Fallback to success chime
      try {
        await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
      } catch (e2) {
        // Ignore fallback errors
      }
    }
  }

  // Play success chime for achievements
  static Future<void> playSuccessChime() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success_chime.mp3'));
    } catch (e) {
      // Ignore notification errors
    }
  }

  // Show notification with sound
  static Future<void> showNotification({
    required String title,
    required String body,
    String? soundType,
    String channelId = 'alert_channel',
    Map<String, dynamic>? payload,
  }) async {
    try {
      // Play sound if specified
      if (soundType != null) {
        await playNotificationSound(soundType);
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        color: const Color(0xFFFFC107), // Gold/Yellow (brand color)
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Bitcoin Mining Pro',
        ),
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        title,
        body,
        notificationDetails,
        payload: payload?.toString(),
      );
    } catch (e) {
      // Ignore notification errors
    }
  }

  // Get channel name
  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'mining_channel':
        return 'Mining Status';
      case 'reward_channel':
        return 'Rewards';
      case 'redemption_channel':
        return 'Redemptions';
      case 'alert_channel':
      default:
        return 'Alerts';
    }
  }

  // Get channel description
  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'mining_channel':
        return 'Shows current mining stats and status';
      case 'reward_channel':
        return 'Notifications for rewards and earnings';
      case 'redemption_channel':
        return 'Notifications for redemptions';
      case 'alert_channel':
      default:
        return 'General app alerts and notifications';
    }
  }

  // Show mining reward notification
  static Future<void> showRewardNotification({
    required double amount,
    required String type,
  }) async {
    await showNotification(
      title: '🎉 Reward Earned!',
      body: 'You earned ${amount.toStringAsFixed(18)} BTC from $type!',
      soundType: 'reward',
      channelId: 'reward_channel',
      payload: {
        'type': 'reward',
        'amount': amount,
        'reward_type': type,
      },
    );
  }

  // Show redemption notification
  static Future<void> showRedemptionNotification({
    required double amount,
    required String method,
  }) async {
    await showNotification(
      title: '💰 Redemption Successful!',
      body: '${amount.toStringAsFixed(18)} BTC redeemed via $method',
      soundType: 'redemption',
      channelId: 'redemption_channel',
      payload: {
        'type': 'redemption',
        'amount': amount,
        'method': method,
      },
    );
  }

  // Show mining status notification
  static Future<void> showMiningNotification({
    required String balance,
    required String hashRate,
    required String duration,
  }) async {
    await showNotification(
      title: '⛏️ Mining Update',
      body:
          'Balance: $balance BTC | Hashrate: $hashRate H/s | Duration: $duration',
      soundType: 'mining',
      channelId: 'mining_channel',
      payload: {
        'type': 'mining_update',
        'balance': balance,
        'hashrate': hashRate,
        'duration': duration,
      },
    );
  }

  // Show general alert notification
  static Future<void> showAlertNotification({
    required String title,
    required String message,
  }) async {
    await showNotification(
      title: title,
      body: message,
      soundType: 'alert',
      channelId: 'alert_channel',
      payload: {
        'type': 'alert',
        'title': title,
        'message': message,
      },
    );
  }

  // Show welcome notification
  static Future<void> showWelcomeNotification() async {
    await showNotification(
      title: '🚀 Welcome to Bitcoin Mining Pro!',
      body:
          'Start mining and earn Bitcoin rewards. Your journey to crypto wealth begins now!',
      soundType: 'alert',
      channelId: 'alert_channel',
      payload: {
        'type': 'welcome',
      },
    );
  }

  // Show level up notification
  static Future<void> showLevelUpNotification({
    required int level,
    required double bonus,
  }) async {
    await showNotification(
      title: '🎯 Level Up!',
      body:
          'Congratulations! You reached level $level and earned ${bonus.toStringAsFixed(18)} BTC bonus!',
      soundType: 'reward',
      channelId: 'reward_channel',
      payload: {
        'type': 'level_up',
        'level': level,
        'bonus': bonus,
      },
    );
  }

  // Show daily bonus notification
  static Future<void> showDailyBonusNotification({
    required double amount,
  }) async {
    await showNotification(
      title: '🎁 Daily Bonus Available!',
      body: 'Claim your daily bonus of ${amount.toStringAsFixed(18)} BTC now!',
      soundType: 'reward',
      channelId: 'reward_channel',
      payload: {
        'type': 'daily_bonus',
        'amount': amount,
      },
    );
  }

  // Show referral bonus notification
  static Future<void> showReferralBonusNotification({
    required String referrerName,
    required double amount,
  }) async {
    await showNotification(
      title: '👥 Referral Bonus!',
      body:
          '$referrerName joined using your code! You earned ${amount.toStringAsFixed(18)} BTC bonus!',
      soundType: 'reward',
      channelId: 'reward_channel',
      payload: {
        'type': 'referral_bonus',
        'referrer_name': referrerName,
        'amount': amount,
      },
    );
  }

  // Show network error notification
  static Future<void> showNetworkErrorNotification() async {
    await showNotification(
      title: '⚠️ Network Error',
      body: 'Please check your internet connection and try again.',
      soundType: 'alert',
      channelId: 'alert_channel',
      payload: {
        'type': 'network_error',
      },
    );
  }

  // Show maintenance notification
  static Future<void> showMaintenanceNotification({
    required String message,
  }) async {
    await showNotification(
      title: '🔧 Maintenance Notice',
      body: message,
      soundType: 'alert',
      channelId: 'alert_channel',
      payload: {
        'type': 'maintenance',
        'message': message,
      },
    );
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      // Ignore notification errors
    }
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      // Ignore notification errors
    }
  }

  // Dispose resources
  static void dispose() {
    _audioPlayer.dispose();
  }
}

