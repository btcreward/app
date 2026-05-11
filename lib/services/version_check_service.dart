import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // 🔧 Step 1: Set default version
      await remoteConfig.setDefaults({
        'latest_version_android': '1.0.0', // fallback if Firebase fails
      });

      // 🌐 Step 2: Fetch latest config from Firebase
      await remoteConfig.fetchAndActivate();

      // ✅ Step 3: Get the latest version from Firebase
      final latestVersion =
          remoteConfig.getString('latest_version_android').trim();

      // 🎯 Step 4: Get the current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      // 🔍 Step 5: Compare versions
      if (_isOutdated(currentVersion, latestVersion)) {
        // Check if the widget is still in the tree before showing dialog
        if (context.mounted) {
          _showForceUpdateDialog(context);
        }
      }
    } catch (e) {
      // Log error silently or handle as needed
    }
  }

  static bool _isOutdated(String current, String latest) {
    try {
      final curr = current.split('.').map(int.parse).toList();
      final latestV = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < latestV.length; i++) {
        if (curr.length <= i || curr[i] < latestV[i]) return true;
        if (curr[i] > latestV[i]) return false;
      }
    } catch (e) {
      // Return false if version parsing fails
    }
    return false;
  }

  static void _showForceUpdateDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🔄 Update Required'),
        content: const Text('Please update the app to the latest version.'),
        actions: [
          TextButton(
            onPressed: () async {
              const url =
                  'https://play.google.com/store/apps/details?id=com.yourcompany.bitcoincloudmining'; // Replace with actual Play Store link
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                // Handle case where URL cannot be launched
              }
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
