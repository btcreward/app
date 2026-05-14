import 'package:bitcoin_cloud_mining/utils/app_logger.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// 🔥 Track app open event
  static Future<void> trackAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      AppLogger.warning('Analytics event failed', error: e);
    }
  }

  /// 🎯 Track login event
  static Future<void> trackLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'email');
    } catch (e) {
      AppLogger.warning('Analytics trackLogin failed', error: e);
    }
  }

  static Future<void> trackTransaction({
    required String type,
    required double amount,
    required String currency,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'wallet_transaction',
        parameters: {
          'transaction_type': type,
          'amount': amount,
          'currency': currency,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics event failed', error: e);
    }
  }

  /// 🎮 Track game played
  static Future<void> trackGamePlayed({
    required String gameName,
    required int duration,
    required double earnings,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_played',
        parameters: {
          'game_name': gameName,
          'duration_seconds': duration,
          'earnings': earnings,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics event failed', error: e);
    }
  }

  /// 🎁 Track reward claimed
  static Future<void> trackRewardClaimed({
    required String rewardType,
    required double amount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'reward_claimed',
        parameters: {
          'reward_type': rewardType,
          'amount': amount,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics event failed', error: e);
    }
  }

  /// 👥 Track referral event
  static Future<void> trackReferral({
    required String action,
    String? referralCode,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'referral_action',
        parameters: {
          'action': action,
          if (referralCode != null) 'referral_code': referralCode,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics event failed', error: e);
    }
  }

  /// 📱 Track notification interaction
  static Future<void> trackNotificationInteraction({
    required String notificationType,
    required String action,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'notification_interaction',
        parameters: {
          'notification_type': notificationType,
          'action': action,
        },
      );
    } catch (e) {
      AppLogger.warning('Analytics event failed', error: e);
    }
  }

  /// 🎯 Track custom event
  static Future<void> trackCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      AppLogger.warning('Analytics event failed', error: e);
    }
  }

  /// 👤 Set user properties
  static Future<void> setUserProperties({
    String? userId,
    String? userType,
    String? registrationDate,
  }) async {
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }
      if (registrationDate != null) {
        await _analytics.setUserProperty(
            name: 'registration_date', value: registrationDate);
      }
    } catch (e) {
      AppLogger.warning('Analytics event failed', error: e);
    }
  }

  /// 🔄 Enable/disable analytics collection
  static Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      AppLogger.warning('Analytics event failed', error: e);
    }
  }
}

