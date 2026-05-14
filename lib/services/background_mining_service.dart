import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mining_notification_service.dart';

class BackgroundMiningService {
  static Timer? _backgroundMiningTimer;
  static bool _isBackgroundMiningActive = false;
  static DateTime? _backgroundMiningStartTime;
  static const int miningDurationMinutes = 30;
  static const double baseMiningRate = 0.000000000000000009;

  // Start background mining service
  static Future<void> startBackgroundMining() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isMining = prefs.getBool('isMining') ?? false;
      final String? miningStartTime = prefs.getString('miningStartTime');

      if (isMining && miningStartTime != null) {
        _backgroundMiningStartTime = DateTime.parse(miningStartTime);
        _isBackgroundMiningActive = true;

        // Start background mining timer
        _startBackgroundMiningTimer();
      }
    } catch (e) {
      debugPrint('Error starting background mining: $e');
    }
  }

  // Start the background mining timer
  static void _startBackgroundMiningTimer() {
    _backgroundMiningTimer?.cancel();
    _backgroundMiningTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isBackgroundMiningActive || _backgroundMiningStartTime == null) {
        timer.cancel();
        return;
      }

      // Check if mining session should complete
      final now = DateTime.now();
      final elapsedMinutes =
          now.difference(_backgroundMiningStartTime!).inMinutes;

      if (elapsedMinutes >= miningDurationMinutes) {
        // Mining session completed
        await _completeBackgroundMining();
        timer.cancel();
      } else {
        // Update mining progress in background
        await _updateBackgroundMiningProgress();
      }
    });
  }

  // Update mining progress in background
  static Future<void> _updateBackgroundMiningProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Calculate current progress
      final now = DateTime.now();
      final elapsedMinutes =
          now.difference(_backgroundMiningStartTime!).inMinutes;
      final progress = (elapsedMinutes / miningDurationMinutes) * 100;

      // Save progress
      await prefs.setDouble('miningProgress', progress);

      // Update notification every minute
      if (elapsedMinutes % 1 == 0) {
        await MiningNotificationService.updateMiningNotification();
      }
    } catch (e) {
      debugPrint('Error updating background mining progress: $e');
    }
  }

  // Complete background mining
  static Future<void> _completeBackgroundMining() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Calculate final earnings
      final now = DateTime.now();
      final elapsedSeconds =
          now.difference(_backgroundMiningStartTime!).inSeconds;
      final earnings = baseMiningRate * elapsedSeconds;

      // Save earnings to be added when user returns
      await prefs.setDouble('pendingMiningEarnings', earnings);

      // Mark mining as completed
      await prefs.setBool('isMining', false);
      await prefs.setString('miningStatus', 'Completed');

      // Update notification
      await MiningNotificationService.completeMiningNotification();

      // Stop background mining
      _isBackgroundMiningActive = false;
      _backgroundMiningStartTime = null;
      _backgroundMiningTimer?.cancel();
      _backgroundMiningTimer = null;
    } catch (e) {
      debugPrint('Error completing background mining: $e');
    }
  }

  // Stop background mining
  static Future<void> stopBackgroundMining() async {
    try {
      _isBackgroundMiningActive = false;
      _backgroundMiningStartTime = null;
      _backgroundMiningTimer?.cancel();
      _backgroundMiningTimer = null;

      // Save state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isMining', false);
    } catch (e) {
      debugPrint('Error stopping background mining: $e');
    }
  }

  // Check if background mining is active
  static bool get isBackgroundMiningActive => _isBackgroundMiningActive;

  // Get pending earnings to be added to wallet
  static Future<double> getPendingEarnings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingEarnings = prefs.getDouble('pendingMiningEarnings') ?? 0.0;

      // Clear pending earnings after retrieving
      await prefs.remove('pendingMiningEarnings');

      return pendingEarnings;
    } catch (e) {
      debugPrint('Error getting pending earnings: $e');
      return 0.0;
    }
  }

  // Initialize background mining service
  static Future<void> initialize() async {
    await startBackgroundMining();
  }

  // Dispose background mining service
  static void dispose() {
    _backgroundMiningTimer?.cancel();
    _backgroundMiningTimer = null;
    _isBackgroundMiningActive = false;
    _backgroundMiningStartTime = null;
  }
}

