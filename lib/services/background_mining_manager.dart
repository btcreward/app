import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mining_notification_service.dart';

class BackgroundMiningManager {
  static Timer? _backgroundTimer;
  static bool _isBackgroundMiningActive = false;
  static DateTime? _backgroundMiningStartTime;
  static const int miningDurationMinutes = 30;
  static const double baseMiningRate = 0.000000000000000009;

  // Start background mining when app goes to background or screen is disposed
  static Future<void> startBackgroundMining() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isMining = prefs.getBool('isMining') ?? false;
      final String? miningStartTime = prefs.getString('miningStartTime');

      if (isMining && miningStartTime != null && !_isBackgroundMiningActive) {
        _backgroundMiningStartTime = DateTime.parse(miningStartTime);
        _isBackgroundMiningActive = true;

        debugPrint('🔥 Background mining started');

        // Start background timer that runs regardless of screen state
        _startBackgroundTimer();
      }
    } catch (e) {
      debugPrint('Error starting background mining: $e');
    }
  }

  // Start background timer that continues even when screen is not mounted
  static void _startBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isBackgroundMiningActive || _backgroundMiningStartTime == null) {
        timer.cancel();
        debugPrint('🛑 Background mining stopped');
        return;
      }

      // Check if mining should complete
      final now = DateTime.now();
      final elapsedMinutes =
          now.difference(_backgroundMiningStartTime!).inMinutes;

      if (elapsedMinutes >= miningDurationMinutes) {
        await _completeBackgroundMining();
        timer.cancel();
        debugPrint('✅ Background mining completed');
      } else {
        // Update mining progress in background
        await _updateBackgroundProgress();
      }
    });
  }

  // Update mining progress in background
  static Future<void> _updateBackgroundProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final elapsedMinutes =
          now.difference(_backgroundMiningStartTime!).inMinutes;
      final progress = (elapsedMinutes / miningDurationMinutes) * 100;

      // Save progress
      await prefs.setDouble('miningProgress', progress);

      // Calculate and save earnings
      final elapsedSeconds =
          now.difference(_backgroundMiningStartTime!).inSeconds;
      final earnings = baseMiningRate * elapsedSeconds;
      await prefs.setDouble('miningEarnings', earnings);

      debugPrint(
          '⛏️ Background mining: ${elapsedMinutes}m, progress: ${progress.toStringAsFixed(1)}%');
    } catch (e) {
      debugPrint('Error updating background progress: $e');
    }
  }

  // Complete background mining
  static Future<void> _completeBackgroundMining() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final elapsedSeconds =
          now.difference(_backgroundMiningStartTime!).inSeconds;
      final finalEarnings = baseMiningRate * elapsedSeconds;

      // Save final earnings
      await prefs.setDouble('pendingMiningEarnings', finalEarnings);
      await prefs.setBool('isMining', false);
      await prefs.setString('miningStatus', 'Completed');

      // Update notification
      await MiningNotificationService.completeMiningNotification();

      // Stop background mining
      _isBackgroundMiningActive = false;
      _backgroundMiningStartTime = null;
      _backgroundTimer?.cancel();
      _backgroundTimer = null;

      debugPrint(
          '💰 Background mining earnings: ${finalEarnings.toStringAsFixed(18)} BTC');
    } catch (e) {
      debugPrint('Error completing background mining: $e');
    }
  }

  // Stop background mining
  static Future<void> stopBackgroundMining() async {
    try {
      _isBackgroundMiningActive = false;
      _backgroundMiningStartTime = null;
      _backgroundTimer?.cancel();
      _backgroundTimer = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isMining', false);

      debugPrint('🛑 Background mining manually stopped');
    } catch (e) {
      debugPrint('Error stopping background mining: $e');
    }
  }

  // Get pending earnings
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

  // Check if background mining is active
  static bool get isBackgroundMiningActive => _isBackgroundMiningActive;

  // Initialize background mining manager
  static Future<void> initialize() async {
    await startBackgroundMining();
  }

  // Dispose background mining manager
  static void dispose() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _isBackgroundMiningActive = false;
    _backgroundMiningStartTime = null;
    debugPrint('🗑️ Background mining manager disposed');
  }
}
