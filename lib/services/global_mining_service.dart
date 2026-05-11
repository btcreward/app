import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mining_notification_service.dart';

class GlobalMiningService {
  static Timer? _globalMiningTimer;
  static bool _isMiningActive = false;
  static DateTime? _miningStartTime;
  static const int miningDurationMinutes = 30;
  static const double baseMiningRate = 0.000000000000000009;

  // Start global mining - this will continue regardless of screen navigation
  static Future<void> startGlobalMining() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isMining = prefs.getBool('isMining') ?? false;
      final String? miningStartTime = prefs.getString('miningStartTime');

      if (isMining && miningStartTime != null && !_isMiningActive) {
        _miningStartTime = DateTime.parse(miningStartTime);
        _isMiningActive = true;

        debugPrint('🔥 Global mining started');

        // Start global timer that runs independently of any screen
        _startGlobalMiningTimer();
      }
    } catch (e) {
      debugPrint('Error starting global mining: $e');
    }
  }

  // Start global mining timer
  static void _startGlobalMiningTimer() {
    _globalMiningTimer?.cancel();
    _globalMiningTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isMiningActive || _miningStartTime == null) {
        timer.cancel();
        debugPrint('🛑 Global mining stopped');
        return;
      }

      // Check if mining should complete
      final now = DateTime.now();
      final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;

      if (elapsedMinutes >= miningDurationMinutes) {
        await _completeGlobalMining();
        timer.cancel();
        debugPrint('✅ Global mining completed');
      } else {
        // Update mining progress
        await _updateGlobalMiningProgress();
      }
    });
  }

  // Update global mining progress
  static Future<void> _updateGlobalMiningProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final elapsedMinutes = now.difference(_miningStartTime!).inMinutes;
      final progress = (elapsedMinutes / miningDurationMinutes) * 100;

      // Save progress
      await prefs.setDouble('miningProgress', progress);

      // Calculate and save earnings
      final elapsedSeconds = now.difference(_miningStartTime!).inSeconds;
      final earnings = baseMiningRate * elapsedSeconds;
      await prefs.setDouble('miningEarnings', earnings);

      // Update notification every 30 seconds
      if (elapsedSeconds % 30 == 0) {
        await MiningNotificationService.updateMiningNotification();
      }

      debugPrint(
          '⛏️ Global mining: ${elapsedMinutes}m ${elapsedSeconds % 60}s, progress: ${progress.toStringAsFixed(1)}%');
    } catch (e) {
      debugPrint('Error updating global mining progress: $e');
    }
  }

  // Complete global mining
  static Future<void> _completeGlobalMining() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final elapsedSeconds = now.difference(_miningStartTime!).inSeconds;
      final finalEarnings = baseMiningRate * elapsedSeconds;

      // Save final earnings
      await prefs.setDouble('pendingMiningEarnings', finalEarnings);
      await prefs.setBool('isMining', false);
      await prefs.setString('miningStatus', 'Completed');

      // Update notification
      await MiningNotificationService.completeMiningNotification();

      // Stop global mining
      _isMiningActive = false;
      _miningStartTime = null;
      _globalMiningTimer?.cancel();
      _globalMiningTimer = null;

      debugPrint(
          '💰 Global mining earnings: ${finalEarnings.toStringAsFixed(18)} BTC');
    } catch (e) {
      debugPrint('Error completing global mining: $e');
    }
  }

  // Stop global mining
  static Future<void> stopGlobalMining() async {
    try {
      _isMiningActive = false;
      _miningStartTime = null;
      _globalMiningTimer?.cancel();
      _globalMiningTimer = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isMining', false);

      debugPrint('🛑 Global mining manually stopped');
    } catch (e) {
      debugPrint('Error stopping global mining: $e');
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

  // Check if global mining is active
  static bool get isGlobalMiningActive => _isMiningActive;

  // Initialize global mining service
  static Future<void> initialize() async {
    await startGlobalMining();
  }

  // Dispose global mining service
  static void dispose() {
    _globalMiningTimer?.cancel();
    _globalMiningTimer = null;
    _isMiningActive = false;
    _miningStartTime = null;
    debugPrint('🗑️ Global mining service disposed');
  }
}
