import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../config/mediation_config.dart';

class AdSlots {
  static const String defaultRewarded = 'default_rewarded';
  static const String defaultInterstitial = 'default_interstitial';
  static const String defaultBanner = 'default_banner';
  static const String defaultNative = 'default_native';

  // Bitcoin Machine
  static const String bitcoinMachineBanner1 = 'bitcoin_machine_banner_1';
  static const String bitcoinMachineRewarded1 = 'bitcoin_machine_rewarded_1';
  static const String bitcoinMachineRewarded2 = 'bitcoin_machine_rewarded_2';
  static const String bitcoinMachineRewarded3 = 'bitcoin_machine_rewarded_3';
  static const String bitcoinMachineInterstitial1 = 'bitcoin_machine_interstitial_1';

  // Bitcoin Blast
  static const String bitcoinBlastBanner1 = 'bitcoin_blast_banner_1';
  static const String bitcoinBlastRewarded1 = 'bitcoin_blast_rewarded_1';
  static const String bitcoinBlastRewarded2 = 'bitcoin_blast_rewarded_2';
  static const String bitcoinBlastInterstitial1 = 'bitcoin_blast_interstitial_1';

  // Contract
  static const String contractBanner1 = 'contract_banner_1';
  static const String contractRewarded1 = 'contract_rewarded_1';

  // Home
  static const String homeBanner1 = 'home_banner_1';
  static const String homeBanner2 = 'home_banner_2';
  static const String homeRewarded1 = 'home_rewarded_1';
  static const String homeRewarded2 = 'home_rewarded_2';

  // Support
  static const String contactSupportBanner1 = 'contact_support_banner_1';

  // Crypto Runner
  static const String cryptoRunnerInterstitial1 = 'crypto_runner_interstitial_1';

  // Game
  static const String gameBanner1 = 'game_banner_1';

  // Hash Rush
  static const String hashRushRewarded1 = 'hash_rush_rewarded_1';
  static const String hashRushInterstitial1 = 'hash_rush_interstitial_1';
  static const String hashRushBanner1 = 'hash_rush_banner_1';

  // Miner Madness
  static const String minerMadnessInterstitial1 = 'miner_madness_interstitial_1';
  static const String minerMadnessBanner1 = 'miner_madness_banner_1';
  static const String minerMadnessRewarded1 = 'miner_madness_rewarded_1';

  // Referral
  static const String referralRewarded1 = 'referral_rewarded_1';

  // Reward
  static const String rewardRewarded1 = 'reward_rewarded_1';
  static const String rewardBanner1 = 'reward_banner_1';

  // Wallet
  static const String walletRewarded1 = 'wallet_rewarded_1';

  // Flip Coin
  static const String flipCoinBanner1 = 'flip_coin_banner_1';
  static const String flipCoinInterstitial1 = 'flip_coin_interstitial_1';
  static const String flipCoinRewarded1 = 'flip_coin_rewarded_1';
  static const String flipCoinRewarded2 = 'flip_coin_rewarded_2';

  // Crypto Craze
  static const String cryptoCrazeBanner1 = 'crypto_craze_banner_1';
  static const String cryptoCrazeInterstitial1 = 'crypto_craze_interstitial_1';
  static const String cryptoCrazeRewarded1 = 'crypto_craze_rewarded_1';
  static const String cryptoCrazeRewarded2 = 'crypto_craze_rewarded_2';
}

class AdService with ChangeNotifier {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _disposed = false;
  bool _isInitializing = false;
  bool _isInitialized = false;

  // Ad configuration
  static const int maxRetryAttempts = 2; // Reduced from 3 to 2
  static const Duration retryDelay =
      Duration(seconds: 3); // Reduced from 5 to 3
  static const Duration adCacheDuration = Duration(minutes: 30);

  // Test mode configuration - set to true for testing
  static const bool forceTestMode = false; // Set to false for production release

  // Unity Ads Configuration - User's real Game IDs
  static const String unityGameIdAndroid =
      '800000486'; // User's Unity Game ID for Android
  static const String unityGameIdIos =
      '800000487'; // User's Unity Game ID for iOS
  static const bool unityTestMode =
      forceTestMode; // Use forceTestMode for Unity test ads

  // Unity initialization retry configuration
  static const int maxUnityInitRetries = 3;
  static const Duration unityInitRetryDelay = Duration(seconds: 5);
  static const Duration unityBannerTimeout = Duration(seconds: 15);

  // Unity Ad Unit IDs - Real placement IDs for your Unity Dashboard
  static const Map<String, Map<String, String>> _unityAdUnitIds = {
    'android': {
      'banner': 'Banner_Android',
      'rewarded': 'Rewarded_Android',
      'interstitial': 'Interstitial_Android',
    },
    'ios': {
      'banner': 'Banner_iOS',
      'rewarded': 'Rewarded_iOS',
      'interstitial': 'Interstitial_iOS',
    },
  };

  // AdMob IDs
  static const Map<String, Map<String, String>> _adMobUnitIds = {
    'android': {
      'native': 'ca-app-pub-9510341737360907/2437697319',
      'banner': 'ca-app-pub-9510341737360907/4171930901',
      'swipeable_banner': 'ca-app-pub-9510341737360907/4171930901',
      'rewarded': 'ca-app-pub-9510341737360907/9667800160',
      'interstitial': 'ca-app-pub-9510341737360907/1980881835',
    },
    'ios': {
      'native': 'ca-app-pub-3940256099942544/3986624511',
      'banner': 'ca-app-pub-3940256099942544/2934735716',
      'swipeable_banner': 'ca-app-pub-3940256099942544/2934735716',
      'rewarded': 'ca-app-pub-3940256099942544/1712485313',
      'interstitial': 'ca-app-pub-3940256099942544/4411468910',
    },
  };

  // Platform and Slot specific AdMob IDs
  static const Map<String, Map<String, String>> _adMobSlotIds = {
    'android': {
      // Default / Fallbacks
      AdSlots.defaultRewarded: 'ca-app-pub-9510341737360907/8650688814',
      AdSlots.defaultInterstitial: 'ca-app-pub-9510341737360907/5360280685',
      AdSlots.defaultBanner: 'ca-app-pub-9510341737360907/4171930901',
      AdSlots.defaultNative: 'ca-app-pub-9510341737360907/2437697319',

      // Bitcoin Machine
      AdSlots.bitcoinMachineBanner1: 'ca-app-pub-9510341737360907/7720750529',
      AdSlots.bitcoinMachineRewarded1: 'ca-app-pub-9510341737360907/9334278157',
      AdSlots.bitcoinMachineRewarded2: 'ca-app-pub-9510341737360907/9332758240',
      AdSlots.bitcoinMachineRewarded3: 'ca-app-pub-9510341737360907/9667800160',
      AdSlots.bitcoinMachineInterstitial1: 'ca-app-pub-9510341737360907/2999738434',

      // Bitcoin Blast
      AdSlots.bitcoinBlastBanner1: 'ca-app-pub-9510341737360907/5094587185',
      AdSlots.bitcoinBlastRewarded1: 'ca-app-pub-9510341737360907/4724949307',
      AdSlots.bitcoinBlastRewarded2: 'ca-app-pub-9510341737360907/2381856999',
      AdSlots.bitcoinBlastInterstitial1: 'ca-app-pub-9510341737360907/2734117345',

      // Contract
      AdSlots.contractBanner1: 'ca-app-pub-9510341737360907/8785963331',
      AdSlots.contractRewarded1: 'ca-app-pub-9510341737360907/9565146785',

      // Home
      AdSlots.homeBanner1: 'ca-app-pub-9510341737360907/6159799990',
      AdSlots.homeBanner2: 'ca-app-pub-9510341737360907/2220554981',
      AdSlots.homeRewarded1: 'ca-app-pub-9510341737360907/5066210171',
      AdSlots.homeRewarded2: 'ca-app-pub-9510341737360907/8826780187',

      // Support
      AdSlots.contactSupportBanner1: 'ca-app-pub-9510341737360907/7529178835',

      // Crypto Runner
      AdSlots.cryptoRunnerInterstitial1: 'ca-app-pub-9510341737360907/9373575096',

      // Game
      AdSlots.gameBanner1: 'ca-app-pub-9510341737360907/7410822395',

      // Hash Rush
      AdSlots.hashRushRewarded1: 'ca-app-pub-9510341737360907/7248077423',
      AdSlots.hashRushInterstitial1: 'ca-app-pub-9510341737360907/9471293380',
      AdSlots.hashRushBanner1: 'ca-app-pub-9510341737360907/6899686507',

      // Miner Madness
      AdSlots.minerMadnessInterstitial1: 'ca-app-pub-9510341737360907/7567641626',
      AdSlots.minerMadnessBanner1: 'ca-app-pub-9510341737360907/6540593854',
      AdSlots.minerMadnessRewarded1: 'ca-app-pub-9510341737360907/4831694852',

      // Referral
      AdSlots.referralRewarded1: 'ca-app-pub-9510341737360907/7266286501',

      // Reward
      AdSlots.rewardRewarded1: 'ca-app-pub-9510341737360907/6200616847',
      AdSlots.rewardBanner1: 'ca-app-pub-9510341737360907/3342064969',

      // Wallet
      AdSlots.walletRewarded1: 'ca-app-pub-9510341737360907/9667800160',

      // Flip Coin
      AdSlots.flipCoinBanner1: 'ca-app-pub-9510341737360907/4273523166',
      AdSlots.flipCoinInterstitial1: 'ca-app-pub-9510341737360907/4123597937',
      AdSlots.flipCoinRewarded1: 'ca-app-pub-9510341737360907/1995750744',
      AdSlots.flipCoinRewarded2: 'ca-app-pub-9510341737360907/9682669070',

      // Crypto Craze
      AdSlots.cryptoCrazeBanner1: 'ca-app-pub-9510341737360907/5227512180',
      AdSlots.cryptoCrazeInterstitial1: 'ca-app-pub-9510341737360907/8158211715',
      AdSlots.cryptoCrazeRewarded1: 'ca-app-pub-9510341737360907/1784375050',
      AdSlots.cryptoCrazeRewarded2: 'ca-app-pub-9510341737360907/6883143128',
    },
    'ios': {
      // Default / Fallbacks
      AdSlots.defaultRewarded: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.defaultInterstitial: 'ca-app-pub-3940256099942544/4411468910',
      AdSlots.defaultBanner: 'ca-app-pub-3940256099942544/2934735716',
      AdSlots.defaultNative: 'ca-app-pub-3940256099942544/3986624511',

      // Bitcoin Machine
      AdSlots.bitcoinMachineBanner1: 'ca-app-pub-3940256099942544/2934735716',
      AdSlots.bitcoinMachineRewarded1: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.bitcoinMachineRewarded2: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.bitcoinMachineRewarded3: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.bitcoinMachineInterstitial1: 'ca-app-pub-3940256099942544/4411468910',

      // Bitcoin Blast
      AdSlots.bitcoinBlastBanner1: 'ca-app-pub-3940256099942544/2934735716',
      AdSlots.bitcoinBlastRewarded1: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.bitcoinBlastRewarded2: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.bitcoinBlastInterstitial1: 'ca-app-pub-3940256099942544/4411468910',

      // Contract
      AdSlots.contractBanner1: 'ca-app-pub-3940256099942544/2934735716',
      AdSlots.contractRewarded1: 'ca-app-pub-3940256099942544/1712485313',

      // Home
      AdSlots.homeBanner1: 'ca-app-pub-3940256099942544/2934735716',
      AdSlots.homeBanner2: 'ca-app-pub-3940256099942544/2934735716',
      AdSlots.homeRewarded1: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.homeRewarded2: 'ca-app-pub-3940256099942544/1712485313',

      // Support
      AdSlots.contactSupportBanner1: 'ca-app-pub-3940256099942544/2934735716',

      // Crypto Runner
      AdSlots.cryptoRunnerInterstitial1: 'ca-app-pub-3940256099942544/4411468910',

      // Game
      AdSlots.gameBanner1: 'ca-app-pub-3940256099942544/2934735716',

      // Hash Rush
      AdSlots.hashRushRewarded1: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.hashRushInterstitial1: 'ca-app-pub-3940256099942544/4411468910',
      AdSlots.hashRushBanner1: 'ca-app-pub-3940256099942544/2934735716',

      // Miner Madness
      AdSlots.minerMadnessInterstitial1: 'ca-app-pub-3940256099942544/4411468910',
      AdSlots.minerMadnessBanner1: 'ca-app-pub-3940256099942544/2934735716',
      AdSlots.minerMadnessRewarded1: 'ca-app-pub-3940256099942544/1712485313',

      // Referral
      AdSlots.referralRewarded1: 'ca-app-pub-3940256099942544/1712485313',

      // Reward
      AdSlots.rewardRewarded1: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.rewardBanner1: 'ca-app-pub-3940256099942544/2934735716',

      // Wallet
      AdSlots.walletRewarded1: 'ca-app-pub-3940256099942544/1712485313',

      // Flip Coin
      AdSlots.flipCoinBanner1: 'ca-app-pub-3940256099942544/2934735716',
      AdSlots.flipCoinInterstitial1: 'ca-app-pub-3940256099942544/4411468910',
      AdSlots.flipCoinRewarded1: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.flipCoinRewarded2: 'ca-app-pub-3940256099942544/1712485313',

      // Crypto Craze
      AdSlots.cryptoCrazeBanner1: 'ca-app-pub-3940256099942544/2934735716',
      AdSlots.cryptoCrazeInterstitial1: 'ca-app-pub-3940256099942544/4411468910',
      AdSlots.cryptoCrazeRewarded1: 'ca-app-pub-3940256099942544/1712485313',
      AdSlots.cryptoCrazeRewarded2: 'ca-app-pub-3940256099942544/1712485313',
    }
  };

  // Platform and Slot specific Unity Placements
  static const Map<String, Map<String, String>> _unitySlotIds = {
    'android': {
      // Fallbacks
      AdSlots.defaultRewarded: 'Rewarded_Android',
      AdSlots.defaultInterstitial: 'Interstitial_Android',
      AdSlots.defaultBanner: 'Banner_Android',

      // Bitcoin Machine
      AdSlots.bitcoinMachineBanner1: 'Banner_Android',
      AdSlots.bitcoinMachineRewarded1: 'Rewarded_Android',
      AdSlots.bitcoinMachineRewarded2: 'Rewarded_Android',
      AdSlots.bitcoinMachineRewarded3: 'Rewarded_Android',
      AdSlots.bitcoinMachineInterstitial1: 'Interstitial_Android',

      // Bitcoin Blast
      AdSlots.bitcoinBlastBanner1: 'Banner_Android',
      AdSlots.bitcoinBlastRewarded1: 'Rewarded_Android',
      AdSlots.bitcoinBlastRewarded2: 'Rewarded_Android',
      AdSlots.bitcoinBlastInterstitial1: 'Interstitial_Android',

      // Contract
      AdSlots.contractBanner1: 'Banner_Android',
      AdSlots.contractRewarded1: 'Rewarded_Android',

      // Home
      AdSlots.homeBanner1: 'Banner_Android',
      AdSlots.homeBanner2: 'Banner_Android',
      AdSlots.homeRewarded1: 'Rewarded_Android',
      AdSlots.homeRewarded2: 'Rewarded_Android',

      // Support
      AdSlots.contactSupportBanner1: 'Banner_Android',

      // Crypto Runner
      AdSlots.cryptoRunnerInterstitial1: 'Interstitial_Android',

      // Game
      AdSlots.gameBanner1: 'Banner_Android',

      // Hash Rush
      AdSlots.hashRushRewarded1: 'Rewarded_Android',
      AdSlots.hashRushInterstitial1: 'Interstitial_Android',
      AdSlots.hashRushBanner1: 'Banner_Android',

      // Miner Madness
      AdSlots.minerMadnessInterstitial1: 'Interstitial_Android',
      AdSlots.minerMadnessBanner1: 'Banner_Android',
      AdSlots.minerMadnessRewarded1: 'Rewarded_Android',

      // Referral
      AdSlots.referralRewarded1: 'Rewarded_Android',

      // Reward
      AdSlots.rewardRewarded1: 'Rewarded_Android',
      AdSlots.rewardBanner1: 'Banner_Android',

      // Wallet
      AdSlots.walletRewarded1: 'Rewarded_Android',

      // Flip Coin
      AdSlots.flipCoinBanner1: 'Banner_Android',
      AdSlots.flipCoinInterstitial1: 'Interstitial_Android',
      AdSlots.flipCoinRewarded1: 'Rewarded_Android',
      AdSlots.flipCoinRewarded2: 'Rewarded_Android',

      // Crypto Craze
      AdSlots.cryptoCrazeBanner1: 'Banner_Android',
      AdSlots.cryptoCrazeInterstitial1: 'Interstitial_Android',
      AdSlots.cryptoCrazeRewarded1: 'Rewarded_Android',
      AdSlots.cryptoCrazeRewarded2: 'Rewarded_Android',
    },
    'ios': {
      // Fallbacks
      AdSlots.defaultRewarded: 'Rewarded_iOS',
      AdSlots.defaultInterstitial: 'Interstitial_iOS',
      AdSlots.defaultBanner: 'Banner_iOS',

      // Bitcoin Machine
      AdSlots.bitcoinMachineBanner1: 'Banner_iOS',
      AdSlots.bitcoinMachineRewarded1: 'Rewarded_iOS',
      AdSlots.bitcoinMachineRewarded2: 'Rewarded_iOS',
      AdSlots.bitcoinMachineRewarded3: 'Rewarded_iOS',
      AdSlots.bitcoinMachineInterstitial1: 'Interstitial_iOS',

      // Bitcoin Blast
      AdSlots.bitcoinBlastBanner1: 'Banner_iOS',
      AdSlots.bitcoinBlastRewarded1: 'Rewarded_iOS',
      AdSlots.bitcoinBlastRewarded2: 'Rewarded_iOS',
      AdSlots.bitcoinBlastInterstitial1: 'Interstitial_iOS',

      // Contract
      AdSlots.contractBanner1: 'Banner_iOS',
      AdSlots.contractRewarded1: 'Rewarded_iOS',

      // Home
      AdSlots.homeBanner1: 'Banner_iOS',
      AdSlots.homeBanner2: 'Banner_iOS',
      AdSlots.homeRewarded1: 'Rewarded_iOS',
      AdSlots.homeRewarded2: 'Rewarded_iOS',

      // Support
      AdSlots.contactSupportBanner1: 'Banner_iOS',

      // Crypto Runner
      AdSlots.cryptoRunnerInterstitial1: 'Interstitial_iOS',

      // Game
      AdSlots.gameBanner1: 'Banner_iOS',

      // Hash Rush
      AdSlots.hashRushRewarded1: 'Rewarded_iOS',
      AdSlots.hashRushInterstitial1: 'Interstitial_iOS',
      AdSlots.hashRushBanner1: 'Banner_iOS',

      // Miner Madness
      AdSlots.minerMadnessInterstitial1: 'Interstitial_iOS',
      AdSlots.minerMadnessBanner1: 'Banner_iOS',
      AdSlots.minerMadnessRewarded1: 'Rewarded_iOS',

      // Referral
      AdSlots.referralRewarded1: 'Rewarded_iOS',

      // Reward
      AdSlots.rewardRewarded1: 'Rewarded_iOS',
      AdSlots.rewardBanner1: 'Banner_iOS',

      // Wallet
      AdSlots.walletRewarded1: 'Rewarded_iOS',

      // Flip Coin
      AdSlots.flipCoinBanner1: 'Banner_iOS',
      AdSlots.flipCoinInterstitial1: 'Interstitial_iOS',
      AdSlots.flipCoinRewarded1: 'Rewarded_iOS',
      AdSlots.flipCoinRewarded2: 'Rewarded_iOS',

      // Crypto Craze
      AdSlots.cryptoCrazeBanner1: 'Banner_iOS',
      AdSlots.cryptoCrazeInterstitial1: 'Interstitial_iOS',
      AdSlots.cryptoCrazeRewarded1: 'Rewarded_iOS',
      AdSlots.cryptoCrazeRewarded2: 'Rewarded_iOS',
    }
  };

  /// Returns the banner ad unit ID for the current platform
  String? getBannerAdUnitId({String? slot}) {
    return _getAdUnitId('banner', network: 'admob', slot: slot);
  }

  // Unity Ad objects
  bool _isUnityInitialized = false;

  // AdMob objects
  NativeAd? _nativeAd; // Legacy single instance
  
  // Multiple AdMob Rewarded ads per slot
  final Map<String, RewardedAd> _admobRewardedAds = {};
  final Map<String, bool> _isAdmobRewardedAdsLoaded = {};
  final Map<String, bool> _isAdmobRewardedAdsLoading = {};

  // Multiple AdMob Interstitial ads per slot
  final Map<String, InterstitialAd> _admobInterstitialAds = {};
  final Map<String, bool> _isAdmobInterstitialAdsLoaded = {};
  final Map<String, bool> _isAdmobInterstitialAdsLoading = {};
  
  // Track currently active Unity rewarded/interstitial slots
  String? _unityRewardedSlot;
  String? _unityInterstitialSlot;

  // Multiple AdMob standard Banner ads per slot
  final Map<String, BannerAd> _adMobStandardBanners = {};
  final Map<String, bool> _isAdMobStandardBannersLoaded = {};
  final Map<String, bool> _isAdMobStandardBannersLoading = {};

  // Multiple Native Ads Manager (AdMob)
  // Format: 'screenId_adType_adId' -> NativeAd
  final Map<String, NativeAd> _nativeAds = {};
  final Map<String, bool> _nativeAdLoadedStates = {};

  // Swipeable carousel ads - per screen instances
  // Format: 'screenId_adType' -> Ad instance
  final Map<String, BannerAd> _swipeableBannerAds = {};
  final Map<String, NativeAd> _swipeableNativeAds = {};
  final Map<String, bool> _swipeableAdLoadedStates = {};

  // AdMob Banner fallbacks for native ads
  final Map<String, BannerAd> _admobFallbackBanners = {};
  final Map<String, bool> _admobFallbackLoadedStates = {};

  // Unity Banner fallback for native ads
  final Map<String, bool> _nativeFallbackStates = {};



  // Banner widget singleton to prevent duplicates
  Widget? _bannerWidgetInstance;

  // Ad states
  final bool _isBannerAdLoaded = false; // Unity banner
  BannerAd?
      _admobBannerAd; // Legacy AdMob banner (to be removed after migration)
  bool _isRewardedAdLoaded = false; // Unity rewarded
  bool _isRewardedAdLoading = false;
  bool _isInterstitialAdLoaded = false; // Unity interstitial
  bool _isInterstitialAdLoading = false;
  bool _isNativeAdLoaded = false; // AdMob native

  // Mediation states
  final bool _isMediationEnabled = MediationConfig.enabled;
  bool _isMediationInitialized = false;
  final Map<String, bool> _mediationNetworkStates = {};

  // Ad tracking
  final Map<String, int> _adShowCounts = {};
  final Map<String, DateTime> _lastAdShowTimes = {};
  final Map<String, int> _adLoadAttempts = {};
  final Map<String, DateTime> _adCacheTimes = {};
  final Map<String, int> _adFailures = {};
  final Map<String, List<Duration>> _adLoadTimes = {};
  bool _isAdShowing = false;

  // Mediation tracking
  final Map<String, int> _mediationAdShows = {};
  final Map<String, int> _mediationAdFailures = {};
  final Map<String, double> _mediationRevenue = {};

  // Performance metrics
  int _totalAdShows = 0;
  int _successfulAdShows = 0;
  int _failedAdShows = 0;
  double _averageAdLoadTime = 0.0;

  // Native ad performance metrics
  int _nativeAdLoadCount = 0;
  int _nativeAdFailCount = 0;
  int _nativeAdClickCount = 0;
  int _nativeAdImpressionCount = 0;
  DateTime? _nativeAdFirstLoadTime;
  double _nativeAdAverageLoadTime = 0.0;

  // Getters for metrics
  Map<String, dynamic> get adMetrics => {
        'total_shows': _totalAdShows,
        'successful_shows': _successfulAdShows,
        'failed_shows': _failedAdShows,
        'success_rate':
            _totalAdShows > 0 ? (_successfulAdShows / _totalAdShows) * 100 : 0,
        'average_load_time': _averageAdLoadTime,
        'ad_failures': _adFailures,
      };

  // Get native ad performance metrics
  Map<String, dynamic> get nativeAdMetrics => {
        'load_count': _nativeAdLoadCount,
        'fail_count': _nativeAdFailCount,
        'click_count': _nativeAdClickCount,
        'impression_count': _nativeAdImpressionCount,
        'success_rate': _nativeAdLoadCount > 0
            ? ((_nativeAdLoadCount - _nativeAdFailCount) / _nativeAdLoadCount) *
                100
            : 0,
        'average_load_time': _nativeAdAverageLoadTime,
        'first_load_time': _nativeAdFirstLoadTime?.toIso8601String(),
        'is_loaded': _isNativeAdLoaded,
      };

  // Public getters for ad loaded states
  bool get isRewardedAdLoaded => _isRewardedAdLoaded || _isAdmobRewardedAdsLoaded.values.contains(true);
  bool get isBannerAdLoaded => _isBannerAdLoaded || _isAdMobStandardBannersLoaded.values.contains(true);
  bool get isNativeAdLoaded => _isNativeAdLoaded;
  bool get isInterstitialAdLoaded =>
      _isInterstitialAdLoaded || _isAdmobInterstitialAdsLoaded.values.contains(true);
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

  // Check if a specific slot is loaded
  bool isSlotRewardedAdLoaded(String slot) {
    return _isRewardedAdLoaded || _isAdmobRewardedAdsLoaded[slot] == true;
  }

  bool isSlotInterstitialAdLoaded(String slot) {
    return _isInterstitialAdLoaded || _isAdmobInterstitialAdsLoaded[slot] == true;
  }

  // Get ad unit ID based on platform, network, ad type and slot
  String _getAdUnitId(String adType, {String network = 'admob', String? slot}) {
    if (kIsWeb) return '';

    String platform;
    if (defaultTargetPlatform == TargetPlatform.android) {
      platform = 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      platform = 'ios';
    } else {
      platform = 'android'; // Default fallback
    }

    String? id;
    if (slot != null) {
      if (network == 'admob') {
        id = _adMobSlotIds[platform]?[slot];
      } else {
        id = _unitySlotIds[platform]?[slot];
      }
    }

    // Fallback to general adType if slot ID is empty/null
    if (id == null || id.isEmpty) {
      if (network == 'admob') {
        id = _adMobUnitIds[platform]?[adType];
      } else {
        id = _unityAdUnitIds[platform]?[adType];
      }
    }

    if (id == null || id.isEmpty) {
      final otherPlatform = platform == 'android' ? 'ios' : 'android';
      if (slot != null) {
        if (network == 'admob') {
          id = _adMobSlotIds[otherPlatform]?[slot];
        } else {
          id = _unitySlotIds[otherPlatform]?[slot];
        }
      }
      if (id == null || id.isEmpty) {
        if (network == 'admob') {
          id = _adMobUnitIds[otherPlatform]?[adType];
        } else {
          id = _unityAdUnitIds[otherPlatform]?[adType];
        }
      }
    }

    return id ?? '';
  }

  String _getUnityGameId() {
    return Platform.isAndroid ? unityGameIdAndroid : unityGameIdIos;
  }

  // Update ad metrics
  void _updateAdMetrics(String adType, bool success, Duration? loadTime) {
    _totalAdShows++;
    if (success) {
      _successfulAdShows++;
      _adShowCounts[adType] = (_adShowCounts[adType] ?? 0) + 1;
      _lastAdShowTimes[adType] = DateTime.now();
    } else {
      _failedAdShows++;
      _adFailures[adType] = (_adFailures[adType] ?? 0) + 1;
    }

    if (loadTime != null) {
      _adLoadTimes[adType] ??= [];
      _adLoadTimes[adType]!.add(loadTime);
      _averageAdLoadTime = _adLoadTimes[adType]!
              .fold(0.0, (sum, time) => sum + time.inMilliseconds) /
          _adLoadTimes[adType]!.length;
    }

    _saveMetrics();
  }

  // Save metrics to SharedPreferences
  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_ad_shows', _totalAdShows);
      await prefs.setInt('successful_ad_shows', _successfulAdShows);
      await prefs.setInt('failed_ad_shows', _failedAdShows);
      await prefs.setDouble('average_ad_load_time', _averageAdLoadTime);
      // Convert ad failures map to JSON string
      final failuresJson =
          _adFailures.entries.map((e) => '${e.key}:${e.value}').join(',');
      await prefs.setString('ad_failures', failuresJson);
    } catch (e) {
      // Ignore errors
    }
  }

  // Load metrics from SharedPreferences
  Future<void> _loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalAdShows = prefs.getInt('total_ad_shows') ?? 0;
      _successfulAdShows = prefs.getInt('successful_ad_shows') ?? 0;
      _failedAdShows = prefs.getInt('failed_ad_shows') ?? 0;
      _averageAdLoadTime = prefs.getDouble('average_ad_load_time') ?? 0.0;

      // Load ad failures from JSON string
      final failuresJson = prefs.getString('ad_failures') ?? '';
      if (failuresJson.isNotEmpty) {
        _adFailures.clear();
        for (final entry in failuresJson.split(',')) {
          final parts = entry.split(':');
          if (parts.length == 2) {
            _adFailures[parts[0]] = int.parse(parts[1]);
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  // Load ad with retry mechanism
  Future<void> _loadAdWithRetry(
    String adType,
    Future<void> Function() loadFunction,
    Function(bool) onLoaded,
  ) async {
    if (kIsWeb) return;

    final startTime = DateTime.now();
    int attempts = 0;
    const int maxAttempts = 2; // Reduced from 3 to 2 attempts
    const Duration retryDelay =
        Duration(seconds: 3); // Reduced from 5 to 3 seconds

    while (attempts < maxAttempts) {
      try {
        await loadFunction();
        final loadTime = DateTime.now().difference(startTime);
        _updateAdMetrics(adType, true, loadTime);
        _adCacheTimes[adType] = DateTime.now();
        onLoaded(true);
        return;
      } catch (e) {
        attempts++;
        _adLoadAttempts[adType] = attempts;

        if (attempts < maxAttempts) {
          await Future.delayed(retryDelay * attempts);
        }
      }
    }

    _updateAdMetrics(adType, false, null);
    onLoaded(false);
  }



  Timer? _bannerAdRefreshTimer;

  // Manual auto-refresh removed to prevent main thread lag.
  // Load banner ad (Exclusively via AdMob)
  Future<void> loadBannerAd({String? slot}) async {
    if (_disposed || kIsWeb) return;

    final activeSlot = slot ?? AdSlots.defaultBanner;

    if (_isAdMobStandardBannersLoaded[activeSlot] == true || _isAdMobStandardBannersLoading[activeSlot] == true) {
      return;
    }

    _isAdMobStandardBannersLoading[activeSlot] = true;
    final adUnitId = _getAdUnitId('banner', network: 'admob', slot: activeSlot);

    if (adUnitId.isEmpty) {
      _isAdMobStandardBannersLoading[activeSlot] = false;
      return;
    }

    try {
      final bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner, // Standard banner (320x50)
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _adMobStandardBanners[activeSlot] = ad as BannerAd;
            _isAdMobStandardBannersLoaded[activeSlot] = true;
            _isAdMobStandardBannersLoading[activeSlot] = false;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _adMobStandardBanners.remove(activeSlot);
            _isAdMobStandardBannersLoaded[activeSlot] = false;
            _isAdMobStandardBannersLoading[activeSlot] = false;
            notifyListeners();
          },
        ),
      );

      await bannerAd.load();
    } catch (e) {
      _isAdMobStandardBannersLoading[activeSlot] = false;
    }
  }

  /// Returns an AdMob banner ad widget when loaded, or a placeholder if not available.
  Future<Widget?> getBannerAdWidget({String? slot}) async {
    if (kIsWeb) return const SizedBox(height: 50);

    final activeSlot = slot ?? AdSlots.defaultBanner;

    // Trigger load if not already loaded or loading
    if (_isAdMobStandardBannersLoaded[activeSlot] != true) {
      await loadBannerAd(slot: activeSlot);

      // Wait up to 3 seconds for it to load
      int elapsedMs = 0;
      while (_isAdMobStandardBannersLoaded[activeSlot] != true && elapsedMs < 3000) {
        await Future.delayed(const Duration(milliseconds: 100));
        elapsedMs += 100;
      }
    }

    final bannerAd = _adMobStandardBanners[activeSlot];
    if (_isAdMobStandardBannersLoaded[activeSlot] == true && bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        child: AdWidget(ad: bannerAd),
      );
    } else {
      return _getBannerPlaceholder('AdMob Banner Ad Loading...');
    }
  }

  // Helper method to get a placeholder widget when banner ad fails to load
  Widget _getBannerPlaceholder(String message) {
    // Use the same dimensions as largeBanner (320x100)
    const double width = 320;
    const double height = 100;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[200]!, Colors.grey[100]!],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.ad_units,
            size: 24,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget getUnityBannerWidget() {
    // Return existing banner widget instance to prevent duplicates
    if (_bannerWidgetInstance != null) {
      return _bannerWidgetInstance!;
    }

    final adUnitId = _getAdUnitId('banner', network: 'unity');

    _bannerWidgetInstance = SizedBox(
      height: 50,
      child: UnityBannerAd(
        placementId: adUnitId,
        onLoad: (placementId) {},
        onClick: (placementId) {},
        onFailed: (placementId, error, message) {
          // Reset banner instance on failure to allow retry
          _bannerWidgetInstance = null;
        },
      ),
    );

    return _bannerWidgetInstance!;
  }



  // Load AdMob rewarded ad
  Future<void> _loadAdmobRewardedAd({String slot = AdSlots.defaultRewarded}) async {
    if (_isAdmobRewardedAdsLoading[slot] == true || _isAdmobRewardedAdsLoaded[slot] == true) return;

    _isAdmobRewardedAdsLoading[slot] = true;
    final adUnitId = _getAdUnitId('rewarded', network: 'admob', slot: slot);

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _admobRewardedAds[slot] = ad;
            _isAdmobRewardedAdsLoaded[slot] = true;
            _isAdmobRewardedAdsLoading[slot] = false;
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _admobRewardedAds.remove(slot);
                _isAdmobRewardedAdsLoaded[slot] = false;
                loadRewardedAd(slot: slot);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _admobRewardedAds.remove(slot);
                _isAdmobRewardedAdsLoaded[slot] = false;
                loadRewardedAd(slot: slot);
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isAdmobRewardedAdsLoading[slot] = false;
            _isAdmobRewardedAdsLoaded[slot] = false;
          },
        ),
      );
    } catch (e) {
      _isAdmobRewardedAdsLoading[slot] = false;
    }
  }

  // Load rewarded ad with better error handling and mediation tracking
  Future<void> loadRewardedAd({String? slot}) async {
    if (_disposed || kIsWeb) return;

    final activeSlot = slot ?? AdSlots.defaultRewarded;

    // Start loading AdMob in background (don't await here to allow parallel loading)
    _loadAdmobRewardedAd(slot: activeSlot);

    // Then try Unity
    if (_unityRewardedSlot != null && _unityRewardedSlot != activeSlot) {
      _isRewardedAdLoaded = false;
      _isRewardedAdLoading = false;
    }

    if (_isRewardedAdLoading) {
      return;
    }

    _isRewardedAdLoading = true;
    _unityRewardedSlot = activeSlot;

    try {
      final adUnitId = _getAdUnitId('rewarded', network: 'unity', slot: activeSlot);

      if (adUnitId.isEmpty) {
        _isRewardedAdLoading = false;
        return;
      }

      // Load Unity Rewarded Ad
      await UnityAds.load(
        placementId: adUnitId,
        onComplete: (placementId) {
          _isRewardedAdLoaded = true;
          _isRewardedAdLoading = false;
          _adCacheTimes['rewarded'] = DateTime.now();
        },
        onFailed: (placementId, error, message) {
          _isRewardedAdLoading = false;
          _isRewardedAdLoaded = false;
        },
      );
    } catch (e) {
      _isRewardedAdLoading = false;
      _isRewardedAdLoaded = false;
    }
  }

  // Auto-refresh native ad periodically
  Timer? _nativeAdRefreshTimer;

  // Load native ad with retry mechanism and auto-refresh
  Future<void> loadNativeAd() async {
    if (_disposed || _isNativeAdLoaded) {
      return;
    }

    final adUnitId = _getAdUnitId('native');
    if (adUnitId.isEmpty) {
      return;
    }

    final startTime = DateTime.now();

    await _loadAdWithRetry(
      'native',
      () async {
        // Dispose existing ad if any
        _nativeAd?.dispose();
        _nativeAd = null;
        _isNativeAdLoaded = false;

        _nativeAd = NativeAd(
          adUnitId: adUnitId,
          factoryId: 'listTile',
          request: const AdRequest(),
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              _isNativeAdLoaded = true;
              _nativeAdLoadCount++;
              _nativeAdFirstLoadTime ??= DateTime.now();

              final loadTime = DateTime.now().difference(startTime);
              _nativeAdAverageLoadTime =
                  (_nativeAdAverageLoadTime * (_nativeAdLoadCount - 1) +
                          loadTime.inMilliseconds) /
                      _nativeAdLoadCount;
            },
            onAdFailedToLoad: (ad, error) {
              _isNativeAdLoaded = false;
              _nativeAdFailCount++;
              ad.dispose();
              _adFailures['native'] = (_adFailures['native'] ?? 0) + 1;

              // Trigger secondary fallback load
              loadNativeAdWithId('native_fallback');
              throw error;
            },
            onAdOpened: (ad) {},
            onAdClosed: (ad) {},
            onAdImpression: (ad) {
              _nativeAdImpressionCount++;
            },
            onAdClicked: (ad) {
              _nativeAdClickCount++;
            },
          ),
        );

        await _nativeAd!.load();
        _adCacheTimes['native'] = DateTime.now();
      },
      (success) {
        _isNativeAdLoaded = success;
      },
    );
  }

  // Auto-refresh removed to prevent main thread lag and excessive memory usage.
  // Force refresh native ad
  Future<void> refreshNativeAd() async {
    _isNativeAdLoaded = false;
    _nativeAd?.dispose();
    _nativeAd = null;
    await loadNativeAd();
  }

  // Get native ad widget with improved error handling and refresh capability
  Widget getNativeAd() {
    if (_isNativeAdLoaded && _nativeAd != null) {
      return Container(
        height: 360,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Native ad content with error boundary
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    try {
                      return AdWidget(ad: _nativeAd!);
                    } catch (e) {
                      // Return fallback UI if ad rendering fails
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.grey, size: 20),
                              SizedBox(height: 4),
                              Text(
                                'Ad Unavailable',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              // Close button for better UX
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    // Optionally track ad dismissal
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(179),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback to the ID-based system
    return getNativeAdWithId('native_fallback');
  }

  // Show rewarded ad with better error handling
  Future<bool> showRewardedAd({
    required Function(double) onRewarded,
    required VoidCallback onAdDismissed,
    String? slot,
  }) async {
    if (kIsWeb) {
      // Simulate ad for web testing
      await Future.delayed(const Duration(seconds: 2));
      onRewarded(5.0); // Give 5x reward for web
      return true;
    }

    if (_isAdShowing) {
      return false;
    }

    final activeSlot = slot ?? AdSlots.defaultRewarded;

    // 1. Try AdMob first
    final isLoaded = _isAdmobRewardedAdsLoaded[activeSlot] == true;
    final admobAd = _admobRewardedAds[activeSlot];

    if (isLoaded && admobAd != null) {
      _isAdShowing = true;
      
      admobAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _isAdShowing = false;
          _isAdmobRewardedAdsLoaded[activeSlot] = false;
          _admobRewardedAds.remove(activeSlot);
          ad.dispose();
          onAdDismissed();
          loadRewardedAd(slot: activeSlot); // Load next in background
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isAdShowing = false;
          _isAdmobRewardedAdsLoaded[activeSlot] = false;
          _admobRewardedAds.remove(activeSlot);
          ad.dispose();
          onAdDismissed();
          loadRewardedAd(slot: activeSlot);
        },
      );

      try {
        await admobAd.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            onRewarded(reward.amount.toDouble());
            _updateAdMetrics('rewarded', true, null);
          },
        );
        return true;
      } catch (e) {
        _isAdShowing = false;
        _isAdmobRewardedAdsLoaded[activeSlot] = false;
        _admobRewardedAds.remove(activeSlot);
        // Continue to Unity fallback
      }
    }

    // 2. Fallback to Unity (if AdMob isn't ready)
    if (_isRewardedAdLoaded) {
    } else {
      if (!_isUnityInitialized) {
        onAdDismissed();
        return false;
      }
      
      await loadRewardedAd(slot: activeSlot);

      // Wait up to 10 seconds for either Unity or AdMob ad to load asynchronously
      int elapsedMs = 0;
      while (!_isRewardedAdLoaded && _isAdmobRewardedAdsLoaded[activeSlot] != true && elapsedMs < 10000) {
        await Future.delayed(const Duration(milliseconds: 200));
        elapsedMs += 200;
      }
      
      if (!_isRewardedAdLoaded && _isAdmobRewardedAdsLoaded[activeSlot] != true) {
        onAdDismissed();
        return false;
      }

      if (_isAdmobRewardedAdsLoaded[activeSlot] == true) {
        return showRewardedAd(
            onRewarded: onRewarded, onAdDismissed: onAdDismissed, slot: activeSlot);
      }
    }

    final adUnitId = _getAdUnitId('rewarded', network: 'unity', slot: activeSlot);

    try {
      _isAdShowing = true;
      await UnityAds.showVideoAd(
        placementId: adUnitId,
        onStart: (placementId) {},
        onComplete: (placementId) {
          _isAdShowing = false;
          _isRewardedAdLoaded = false;
          onRewarded(1.0); // Default reward amount
          loadRewardedAd(slot: activeSlot);
          _updateAdMetrics('rewarded', true, null);
        },
        onSkipped: (placementId) {
          _isAdShowing = false;
          _isRewardedAdLoaded = false;
          onAdDismissed();
          loadRewardedAd(slot: activeSlot);
          _updateAdMetrics('rewarded', false, null);
        },
        onFailed: (placementId, error, message) {
          _isAdShowing = false;
          _isRewardedAdLoaded = false;
          onAdDismissed();
          loadRewardedAd(slot: activeSlot);
          _updateAdMetrics('rewarded', false, null);
        },
      );

      return true;
    } catch (e) {
      _isAdShowing = false;
      _isRewardedAdLoaded = false;
      loadRewardedAd(slot: activeSlot);
      onAdDismissed();
      _updateAdMetrics('rewarded', false, null);
      return false;
    }
  }

  // Load AdMob interstitial ad
  Future<void> _loadAdmobInterstitialAd({String slot = AdSlots.defaultInterstitial}) async {
    if (_isAdmobInterstitialAdsLoading[slot] == true || _isAdmobInterstitialAdsLoaded[slot] == true) return;

    _isAdmobInterstitialAdsLoading[slot] = true;
    final adUnitId = _getAdUnitId('interstitial', network: 'admob', slot: slot);

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _admobInterstitialAds[slot] = ad;
            _isAdmobInterstitialAdsLoaded[slot] = true;
            _isAdmobInterstitialAdsLoading[slot] = false;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _admobInterstitialAds.remove(slot);
                _isAdmobInterstitialAdsLoaded[slot] = false;
                loadInterstitialAd(slot: slot);
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _admobInterstitialAds.remove(slot);
                _isAdmobInterstitialAdsLoaded[slot] = false;
                loadInterstitialAd(slot: slot);
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isAdmobInterstitialAdsLoading[slot] = false;
            _isAdmobInterstitialAdsLoaded[slot] = false;
          },
        ),
      );
    } catch (e) {
      _isAdmobInterstitialAdsLoading[slot] = false;
    }
  }

  // Load Unity interstitial ad
  Future<void> loadInterstitialAd({String? slot}) async {
    if (_disposed || kIsWeb) return;

    final activeSlot = slot ?? AdSlots.defaultInterstitial;

    // Start loading AdMob in background
    _loadAdmobInterstitialAd(slot: activeSlot);

    if (_unityInterstitialSlot != null && _unityInterstitialSlot != activeSlot) {
      _isInterstitialAdLoaded = false;
      _isInterstitialAdLoading = false;
    }

    if (_isInterstitialAdLoading || !_isUnityInitialized) {
      return;
    }

    _isInterstitialAdLoading = true;
    _isInterstitialAdLoaded = false;
    _unityInterstitialSlot = activeSlot;

    try {
      final adUnitId = _getAdUnitId('interstitial', network: 'unity', slot: activeSlot);

      if (adUnitId.isEmpty) {
        _isInterstitialAdLoading = false;
        return;
      }

      await UnityAds.load(
        placementId: adUnitId,
        onComplete: (placementId) {
          _isInterstitialAdLoaded = true;
          _isInterstitialAdLoading = false;
          _updateAdMetrics('interstitial', true, null);
        },
        onFailed: (placementId, error, message) {
          _isInterstitialAdLoaded = false;
          _isInterstitialAdLoading = false;
          _updateAdMetrics('interstitial', false, null);
        },
      );
    } catch (e) {
      _isInterstitialAdLoaded = false;
      _isInterstitialAdLoading = false;
      _updateAdMetrics('interstitial', false, null);
    }
  }

  // Show Unity interstitial ad
  // Show interstitial ad
  Future<bool> showInterstitialAd({
    VoidCallback? onAdDismissed,
    String? slot,
  }) async {
    if (_isAdShowing) {
      return false;
    }

    final activeSlot = slot ?? AdSlots.defaultInterstitial;

    // 1. Try AdMob first
    final isLoaded = _isAdmobInterstitialAdsLoaded[activeSlot] == true;
    final admobAd = _admobInterstitialAds[activeSlot];

    if (isLoaded && admobAd != null) {
      _isAdShowing = true;
      
      admobAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _isAdShowing = false;
          _isAdmobInterstitialAdsLoaded[activeSlot] = false;
          _admobInterstitialAds.remove(activeSlot);
          ad.dispose();
          onAdDismissed?.call();
          loadInterstitialAd(slot: activeSlot); // Load next in background
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isAdShowing = false;
          _isAdmobInterstitialAdsLoaded[activeSlot] = false;
          _admobInterstitialAds.remove(activeSlot);
          ad.dispose();
          onAdDismissed?.call();
          loadInterstitialAd(slot: activeSlot);
        },
      );

      try {
        await admobAd.show();
        _updateAdMetrics('interstitial', true, null);
        return true;
      } catch (e) {
        _isAdShowing = false;
        _isAdmobInterstitialAdsLoaded[activeSlot] = false;
        _admobInterstitialAds.remove(activeSlot);
        // Continue to Unity fallback
      }
    }

    // 2. Fallback to Unity
    if (_isInterstitialAdLoaded) {
    } else {
      if (!_isUnityInitialized) {
        onAdDismissed?.call();
        return false;
      }

      await loadInterstitialAd(slot: activeSlot);

      // Wait up to 10 seconds for either Unity or AdMob interstitial to load
      int elapsedMs = 0;
      while (!_isInterstitialAdLoaded && _isAdmobInterstitialAdsLoaded[activeSlot] != true && elapsedMs < 10000) {
        await Future.delayed(const Duration(milliseconds: 200));
        elapsedMs += 200;
      }

      if (!_isInterstitialAdLoaded && _isAdmobInterstitialAdsLoaded[activeSlot] != true) {
        onAdDismissed?.call();
        return false;
      }

      // If AdMob loaded while waiting for Unity
      if (_isAdmobInterstitialAdsLoaded[activeSlot] == true) {
        return showInterstitialAd(onAdDismissed: onAdDismissed, slot: activeSlot);
      }
    }

    final adUnitId = _getAdUnitId('interstitial', network: 'unity', slot: activeSlot);

    try {
      if (adUnitId.isEmpty) {
        onAdDismissed?.call();
        return false;
      }

      _isAdShowing = true;
      await UnityAds.showVideoAd(
        placementId: adUnitId,
        onComplete: (placementId) {
          _isAdShowing = false;
          _isInterstitialAdLoaded = false;
          onAdDismissed?.call();
          loadInterstitialAd(slot: activeSlot);
          _updateAdMetrics('interstitial', true, null);
        },
        onFailed: (placementId, error, message) {
          _isAdShowing = false;
          _isInterstitialAdLoaded = false;
          onAdDismissed?.call();
          loadInterstitialAd(slot: activeSlot);
          _updateAdMetrics('interstitial', false, null);
        },
        onSkipped: (placementId) {
          _isAdShowing = false;
          _isInterstitialAdLoaded = false;
          onAdDismissed?.call();
          loadInterstitialAd(slot: activeSlot);
          _updateAdMetrics('interstitial', false, null);
        },
      );

      return true;
    } catch (e) {
      _isAdShowing = false;
      _isInterstitialAdLoaded = false;
      onAdDismissed?.call();
      _updateAdMetrics('interstitial', false, null);
      return false;
    }
  }


  // Get AdMob banner ad widget (Exclusively via AdMob)
  Widget getBannerAd({String? slot}) {
    if (kIsWeb) return const SizedBox(height: 50);

    final activeSlot = slot ?? AdSlots.defaultBanner;
    final bannerAd = _adMobStandardBanners[activeSlot];

    if (_isAdMobStandardBannersLoaded[activeSlot] == true && bannerAd != null) {
      try {
        return Container(
          alignment: Alignment.center,
          width: bannerAd.size.width.toDouble(),
          height: bannerAd.size.height.toDouble(),
          child: AdWidget(ad: bannerAd),
        );
      } catch (e) {
        return const SizedBox(height: 50);
      }
    }

    // Trigger load in background if not already loading/loaded
    loadBannerAd(slot: activeSlot);
    return const SizedBox(height: 50);
  }

  // Initialize ads
  Future<void> initialize() async {
    if (_disposed || kIsWeb || _isInitializing || _isInitialized) return;

    _isInitializing = true;
    debugPrint('🎯 Hash Rush: Initializing ads...');

    try {
      // Initialize AdMob (for native ads only)
      await MobileAds.instance.initialize();
      await _loadMetrics();

      // Initialize Unity Ads (for banner and rewarded ads)
      await _initializeUnityAds();

      // Initialize mediation
      await _initializeMediation();

      // Wait a moment for Unity Ads to be fully ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Preload ads (both AdMob and Unity)
      await Future.wait([
        loadBannerAd(), // Unity banner
        loadRewardedAd(), // AdMob + Unity rewarded
        loadInterstitialAd(), // AdMob + Unity interstitial
        loadNativeAd(), // AdMob native
      ]);

      _isInitialized = true;
      debugPrint('🎯 Hash Rush: All ads initialized. Status: $_isInitialized');
      debugPrint('🎯 Hash Rush: Rewarded ad loaded: $isRewardedAdLoaded');
      debugPrint(
          '🎯 Hash Rush: Interstitial ad loaded: $isInterstitialAdLoaded');
      debugPrint('🎯 Hash Rush: Banner ad loaded: $_isBannerAdLoaded');
      debugPrint('🎯 Hash Rush: Native ad loaded: $_isNativeAdLoaded');
    } catch (e, stackTrace) {
      debugPrint('🎯 Hash Rush: AdService initialization error: $e');
      debugPrint('🎯 Hash Rush: Stack trace: $stackTrace');
    } finally {
      _isInitializing = false;
    }
  }



  Future<void> _initializeUnityAds() async {
    try {
      final gameId = _getUnityGameId();
      debugPrint('\n=== UNITY ADS INITIALIZATION DEBUG ===');
      debugPrint('🎮 Game ID: $gameId');
      debugPrint('🧪 Test Mode: $unityTestMode');
      debugPrint('📱 Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
      debugPrint('📚 Unity Ads Plugin Version: 0.3.20');
      debugPrint('🔍 Checking Unity Ads availability...');

      // Check if Unity Ads is already initialized
      try {
        final isInitialized = await UnityAds.isInitialized();
        debugPrint('📊 Unity Ads isInitialized: $isInitialized');
        if (isInitialized) {
          _isUnityInitialized = true;
          debugPrint('✅ Unity Ads already initialized!');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Could not check Unity Ads initialization status: $e');
      }

      debugPrint('🚀 Starting Unity Ads initialization...');

      // Initialize Unity Ads with comprehensive error handling
      final completer = Completer<void>();
      bool hasCompleted = false;

      // Set timeout for initialization
      final timeoutTimer = Timer(const Duration(seconds: 45), () {
        if (!hasCompleted) {
          hasCompleted = true;
          _isUnityInitialized = false;
          debugPrint('⏰ Unity Ads initialization TIMEOUT after 45 seconds!');
          debugPrint('🔴 This usually means:');
          debugPrint('   1. Game ID is invalid: $gameId');
          debugPrint('   2. Network connectivity issues');
          debugPrint('   3. Unity Ads servers are down');
          debugPrint('   4. Unity Ads plugin is not properly installed');
          completer.completeError('Unity Ads initialization timeout');
        }
      });

      debugPrint('📞 Calling UnityAds.init()...');

      await UnityAds.init(
        gameId: gameId,
        testMode: unityTestMode,
        onComplete: () {
          debugPrint('📢 Unity Ads onComplete callback triggered!');
          if (!hasCompleted) {
            hasCompleted = true;
            timeoutTimer.cancel();
            _isUnityInitialized = true;
            debugPrint('✅ Unity Ads initialized successfully!');
            debugPrint('🎯 Banner Ad Unit: ${_getAdUnitId("banner")}');
            debugPrint('🎁 Rewarded Ad Unit: ${_getAdUnitId("rewarded")}');
            debugPrint('=== UNITY ADS INITIALIZATION SUCCESS ===\n');
            completer.complete();
          }
        },
        onFailed: (error, message) {
          debugPrint('📢 Unity Ads onFailed callback triggered!');
          if (!hasCompleted) {
            hasCompleted = true;
            timeoutTimer.cancel();
            _isUnityInitialized = false;
            debugPrint('❌ Unity Ads initialization FAILED!');
            debugPrint('🔴 Error Code: $error');
            debugPrint('💬 Error Message: $message');
            debugPrint('🔍 Possible solutions:');
            debugPrint('   1. Verify Game ID in Unity Dashboard: $gameId');
            debugPrint('   2. Check if game is published in Unity Dashboard');
            debugPrint('   3. Ensure Unity Ads is enabled for your project');
            debugPrint('   4. Check network connectivity');
            debugPrint('=== UNITY ADS INITIALIZATION FAILED ===\n');
            completer.completeError(
                'Unity Ads initialization failed: $error - $message');
          }
        },
      );

      debugPrint('🕰️ Waiting for Unity Ads initialization to complete...');

      // Wait for initialization to complete
      await completer.future;
    } catch (e, stackTrace) {
      _isUnityInitialized = false;
      debugPrint('💥 Unity Ads initialization EXCEPTION: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      debugPrint('🔧 This might be a plugin integration issue.');
      debugPrint('=== UNITY ADS INITIALIZATION EXCEPTION ===\n');
    }
  }

  // Initialize mediation configuration
  Future<void> _initializeMediation() async {
    if (!_isMediationEnabled) return;

    try {
      // Configure mediation settings
      await _configureMediationSettings();

      // Initialize mediation networks
      await _initializeMediationNetworks();

      _isMediationInitialized = true;

      if (kDebugMode) {
        print('✅ Mediation initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mediation initialization failed: $e');
      }
    }
  }

  // Configure mediation settings
  Future<void> _configureMediationSettings() async {
    try {
      // Configure AdMob mediation settings
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.pg,
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          testDeviceIds: MediationConfig.enableTestDevices
              ? MediationConfig.testDeviceIds
              : null,
        ),
      );

      if (kDebugMode) {
        print('✅ Mediation settings configured');
        if (MediationConfig.enableTestDevices) {
          print('🔧 Test devices enabled: ${MediationConfig.testDeviceIds}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mediation settings configuration failed: $e');
      }
    }
  }

  // Initialize mediation networks
  Future<void> _initializeMediationNetworks() async {
    final networks = MediationConfig.supportedNetworks;

    for (final network in networks) {
      try {
        await _initializeMediationNetwork(network);
        _mediationNetworkStates[network] = true;

        if (kDebugMode) {
          print('✅ $network mediation network initialized');
        }
      } catch (e) {
        _mediationNetworkStates[network] = false;
        if (kDebugMode) {
          print('❌ $network mediation network failed: $e');
        }
      }
    }
  }

  // Initialize specific mediation network
  Future<void> _initializeMediationNetwork(String network) async {
    switch (network) {
      case 'unity_ads':
        // Unity Ads is already initialized via build.gradle
        break;
      case 'facebook_audience_network':
        // Facebook Audience Network initialization
        break;
      case 'applovin':
        // AppLovin initialization
        break;
      case 'iron_source':
        // IronSource initialization
        break;
      default:
        if (kDebugMode) {
          print('⚠️ Unknown mediation network: $network');
        }
    }
  }

  // Get mediation status
  Map<String, dynamic> get mediationStatus => {
        'enabled': _isMediationEnabled,
        'initialized': _isMediationInitialized,
        'networks': _mediationNetworkStates,
        'config': MediationConfig.config,
        'metrics': {
          'ad_shows': _mediationAdShows,
          'ad_failures': _mediationAdFailures,
          'revenue': _mediationRevenue,
        },
      };

  // Check if mediation is working properly
  bool get isMediationWorking {
    if (!_isMediationEnabled) return false;
    if (!_isMediationInitialized) return false;

    // Check if at least one network is active
    final activeNetworks =
        _mediationNetworkStates.values.where((state) => state).length;
    return activeNetworks > 0;
  }

  // Get mediation performance summary
  Map<String, dynamic> get mediationPerformance {
    final totalShows =
        _mediationAdShows.values.fold(0, (sum, count) => sum + count);
    final totalFailures =
        _mediationAdFailures.values.fold(0, (sum, count) => sum + count);
    final totalRevenue =
        _mediationRevenue.values.fold(0.0, (sum, revenue) => sum + revenue);

    return {
      'total_shows': totalShows,
      'total_failures': totalFailures,
      'total_revenue': totalRevenue,
      'success_rate': totalShows > 0
          ? ((totalShows - totalFailures) / totalShows) * 100
          : 0,
      'is_working': isMediationWorking,
      'active_networks':
          _mediationNetworkStates.values.where((state) => state).length,
    };
  }

  // Update mediation metrics
  void _updateMediationMetrics(String network, bool success, double? revenue) {
    if (success) {
      _mediationAdShows[network] = (_mediationAdShows[network] ?? 0) + 1;
      if (revenue != null) {
        _mediationRevenue[network] =
            (_mediationRevenue[network] ?? 0) + revenue;
      }
    } else {
      _mediationAdFailures[network] = (_mediationAdFailures[network] ?? 0) + 1;
    }

    // Log mediation metrics for debugging
    if (kDebugMode) {
      print('📊 Mediation Metrics Updated:');
      print('   Network: $network');
      print('   Success: $success');
      print('   Revenue: $revenue');
      print('   Total Shows: ${_mediationAdShows[network]}');
      print('   Total Failures: ${_mediationAdFailures[network]}');
    }
  }

  // Test mediation functionality
  Future<void> testMediation() async {
    if (!_isMediationEnabled) {
      if (kDebugMode) {
        print('❌ Mediation is disabled');
      }
      return;
    }

    if (kDebugMode) {
      print('🧪 Testing Mediation...');
      print('   Enabled: $_isMediationEnabled');
      print('   Initialized: $_isMediationInitialized');
      print('   Networks: $_mediationNetworkStates');
      print('   Metrics:');
      print('     Shows: $_mediationAdShows');
      print('     Failures: $_mediationAdFailures');
      print('     Revenue: $_mediationRevenue');
    }

    // Test ad loading with mediation
    try {
      await loadRewardedAd();
      await loadBannerAd();
      await loadNativeAd();

      if (kDebugMode) {
        print('✅ Mediation test completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mediation test failed: $e');
      }
    }
  }

  // Note: Main dispose method is implemented later in the file with proper cleanup

  // Reset ad metrics
  Future<void> resetMetrics() async {
    _totalAdShows = 0;
    _successfulAdShows = 0;
    _failedAdShows = 0;
    _averageAdLoadTime = 0.0;
    _adShowCounts.clear();
    _lastAdShowTimes.clear();
    _adLoadAttempts.clear();
    _adCacheTimes.clear();
    _adFailures.clear();
    _adLoadTimes.clear();

    await _saveMetrics();
  }

  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // Home_Banner_Ad
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // Rewarded_BTC_Ad
  static const String nativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110'; // Native_Contract_Card

  // Unity Ads doesn't need getRewardedAd function like AdMob
  // Use isRewardedAdLoaded getter and showRewardedAd() function instead
  Future<bool> getRewardedAdStatus() async {
    if (!_isUnityInitialized) {
      return false;
    }

    if (!_isRewardedAdLoaded && !_isRewardedAdLoading) {
      await loadRewardedAd();
    }

    return _isRewardedAdLoaded;
  }

  // Validate native ad size and layout
  Map<String, dynamic> validateNativeAdSize() {
    final result = {
      'container_height': 250,
      'media_height': 150,
      'button_height': 64,
      'total_estimated_height': 250,
      'recommendations': <String>[],
    };

    // Check if container height is sufficient
    if ((result['container_height'] as int) < 200) {
      (result['recommendations'] as List<String>)
          .add('Container height should be at least 200px');
    }

    // Check if media height is appropriate
    if ((result['media_height'] as int) < 120) {
      (result['recommendations'] as List<String>)
          .add('Media height should be at least 120dp');
    }

    // Check if button height is touch-friendly
    if ((result['button_height'] as int) < 48) {
      (result['recommendations'] as List<String>)
          .add('Button height should be at least 48dp for touch targets');
    }

    return result;
  }

  // Native ad loading configuration
  static const int _maxRetryAttempts = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 30);
  static const Duration _fallbackTimeout = Duration(seconds: 5);

  final Map<String, Timer> _nativeAdTimers = {};
  final Map<String, int> _nativeAdRetryCounts = {};

  // Multiple Native Ads Methods with improved fallback logic
  Future<void> loadNativeAdWithId(String adId, {bool isRetry = false}) async {
    if (kIsWeb) return;

    debugPrint('===== Loading Native Ad With ID: $adId =====');
    debugPrint(
        'Current fallback state: ${_nativeFallbackStates[adId] ?? false}');
    debugPrint('Is retry attempt: $isRetry');

    // Cancel any existing timer for this ad
    _nativeAdTimers[adId]?.cancel();

    // Initialize retry count if not exists
    _nativeAdRetryCounts[adId] = _nativeAdRetryCounts[adId] ?? 0;

    // Dispose existing ad if any
    _nativeAds[adId]?.dispose();
    _nativeAds.remove(adId);
    _nativeAdLoadedStates[adId] = false;
    
    // Maintain cache size
    _limitNativeAdCache();

    // Enable fallback by default when starting to load a new ad
    _nativeFallbackStates[adId] = true;

    final adUnitId = _getAdUnitId('native');
    if (adUnitId.isEmpty) {
      debugPrint('Empty ad unit ID for native ad');
      _scheduleFallback(adId);
      return;
    }

    debugPrint('Using ad unit ID: $adUnitId');
    final startTime = DateTime.now();

    // Set up a timeout for the native ad load
    _nativeAdTimers[adId] = Timer(_fallbackTimeout, () {
      if (!(_nativeAdLoadedStates[adId] ?? false)) {
        debugPrint('Native ad load timed out, falling back to Unity banner');
        _nativeFallbackStates[adId] = true;
        _notifyAdStateChange();
      }
    });

    try {
      await _loadAdWithRetry(
        'native',
        () async {
          debugPrint('🔄 Attempting to load native ad with ID: $adId');
          debugPrint('🎯 Using AdMob Unit ID: $adUnitId');

          // Try different factory IDs to avoid white screen
          String factoryId = 'listTile';
          if (_nativeAdRetryCounts[adId] != null &&
              _nativeAdRetryCounts[adId]! > 0) {
            // Try alternative factory IDs on retry
            final alternatives = ['adplacer', 'listTile', 'gridTile'];
            factoryId =
                alternatives[_nativeAdRetryCounts[adId]! % alternatives.length];
            debugPrint('🔄 Retry attempt, using factory ID: $factoryId');
          }

          final nativeAd = NativeAd(
            adUnitId: adUnitId,
            factoryId: factoryId, // Dynamic factory ID to avoid white screen
            request: const AdRequest(),
            nativeTemplateStyle: NativeTemplateStyle(
              templateType: TemplateType.medium,
              mainBackgroundColor: Colors.white,
              cornerRadius: 8.0,
              callToActionTextStyle: NativeTemplateTextStyle(
                textColor: Colors.white,
                backgroundColor: Colors.blue,
                style: NativeTemplateFontStyle.bold,
                size: 16.0,
              ),
              primaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.black87,
                style: NativeTemplateFontStyle.bold,
                size: 16.0,
              ),
              secondaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.black54,
                style: NativeTemplateFontStyle.normal,
                size: 14.0,
              ),
              tertiaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.black45,
                style: NativeTemplateFontStyle.normal,
                size: 12.0,
              ),
            ),
            listener: NativeAdListener(
              onAdLoaded: (ad) {
                _nativeAdTimers[adId]?.cancel();
                debugPrint('✅ Native ad loaded successfully for ID: $adId');
                debugPrint('📊 Ad details: ${ad.toString()}');
                _nativeAdLoadedStates[adId] = true;
                _nativeAdLoadCount++;
                _nativeAdFirstLoadTime ??= DateTime.now();
                _nativeAdRetryCounts[adId] =
                    0; // Reset retry counter on success

                // Add a small delay to ensure ad is fully rendered
                Future.delayed(const Duration(milliseconds: 500), () {
                  debugPrint('🎯 Native ad should be visible now');
                });

                final loadTime = DateTime.now().difference(startTime);
                _nativeAdAverageLoadTime =
                    (_nativeAdAverageLoadTime * (_nativeAdLoadCount - 1) +
                            loadTime.inMilliseconds) /
                        _nativeAdLoadCount;

                // Update mediation metrics for successful load
                if (_isMediationEnabled) {
                  _updateMediationMetrics('admob', true, null);
                }
                _notifyAdStateChange();
              },
              onAdFailedToLoad: (ad, error) {
                _nativeAdTimers[adId]?.cancel();
                debugPrint('Native ad failed to load: ${error.message}');
                debugPrint('Error code: ${error.code}');
                debugPrint('Error domain: ${error.domain}');

                _nativeAdLoadedStates[adId] = false;
                _nativeAdFailCount++;
                ad.dispose();
                _adFailures['native'] = (_adFailures['native'] ?? 0) + 1;

                // Handle retry logic
                _handleNativeAdLoadFailure(adId, error);
              },
              onAdClicked: (ad) {
                _nativeAdClickCount++;
                // Update mediation metrics for click
                if (_isMediationEnabled) {
                  _updateMediationMetrics('admob', true, null);
                }
              },
              onAdOpened: (ad) {},
              onAdClosed: (ad) {},
              onAdImpression: (ad) {
                _nativeAdImpressionCount++;
                // Update mediation metrics for impression
                if (_isMediationEnabled) {
                  _updateMediationMetrics('admob', true, null);
                }
              },
            ),
          );

          _nativeAds[adId] = nativeAd;
          await nativeAd.load();
          return;
        },
        (success) {
          _nativeAdLoadedStates[adId] = success;
          if (!success) {
            _handleNativeAdLoadFailure(adId, null);
          }
        },
      );
    } catch (e) {
      debugPrint('Exception while loading native ad: $e');
      _handleNativeAdLoadFailure(adId, e);
    }
  }

  void _handleNativeAdLoadFailure(String adId, dynamic error) {
    final retryCount = _nativeAdRetryCounts[adId] ?? 0;

    if (retryCount < _maxRetryAttempts) {
      // Calculate exponential backoff delay
      final delay = Duration(
          milliseconds:
              (_initialRetryDelay.inMilliseconds * (1 << (retryCount - 1)))
                  .clamp(_initialRetryDelay.inMilliseconds,
                      _maxRetryDelay.inMilliseconds));

      debugPrint('Scheduling retry $retryCount in ${delay.inSeconds} seconds');

      _nativeAdRetryCounts[adId] = retryCount + 1;
      Future.delayed(delay, () => loadNativeAdWithId(adId, isRetry: true));
    } else {
      debugPrint('Max retry attempts reached, falling back to Unity banner');
      _scheduleFallback(adId);
    }
  }

  void _scheduleFallback(String adId) {
    _nativeFallbackStates[adId] = true;
    _notifyAdStateChange();

    // Load AdMob banner as the exclusive fallback
    _loadAdmobFallbackBanner(adId);
  }

  void _loadAdmobFallbackBanner(String adId) {
    if (_admobFallbackLoadedStates[adId] == true) return;

    final bannerAdId = _getAdUnitId('banner', network: 'admob');
    if (bannerAdId.isEmpty) return;

    debugPrint('🔄 Loading AdMob Fallback Banner for: $adId');

    final bannerAd = BannerAd(
      adUnitId: bannerAdId,
      size: AdSize.mediumRectangle, // Use medium rectangle for native slots
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _admobFallbackLoadedStates[adId] = true;
          _notifyAdStateChange();
          debugPrint('✅ AdMob Fallback Banner loaded for: $adId');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _admobFallbackLoadedStates[adId] = false;
          debugPrint('❌ AdMob Fallback Banner failed: $error');
        },
      ),
    );

    _admobFallbackBanners[adId] = bannerAd;
    bannerAd.load();
  }

  Widget _getAdMobFallbackWidget(String adId) {
    final bannerAd = _admobFallbackBanners[adId];
    if (bannerAd == null || _admobFallbackLoadedStates[adId] != true) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 360,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'AdMob Banner Fallback',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    _admobFallbackLoadedStates[adId] = false;
                    _loadAdmobFallbackBanner(adId);
                    _notifyAdStateChange();
                  },
                  child: Icon(Icons.refresh, color: Colors.blue[700], size: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AdWidget(ad: bannerAd),
            ),
          ),
        ],
      ),
    );
  }

  void _notifyAdStateChange() {
    // Notify listeners about the ad state change
    // This can be used to trigger UI updates if needed
    notifyListeners();
  }

  bool isNativeAdLoadedWithId(String adId) {
    return _nativeAdLoadedStates[adId] ?? false;
  }

  Widget getNativeAdWithId(String adId) {
    debugPrint('===== Native Ad Debug =====');
    debugPrint('Ad ID: $adId');

    final nativeAd = _nativeAds[adId];
    final isLoaded = _nativeAdLoadedStates[adId] ?? false;
    final shouldShowFallback = _nativeFallbackStates[adId] ?? false;

    debugPrint('Native Ad Loaded: $isLoaded');
    debugPrint('Should Show Fallback: $shouldShowFallback');

    // Enhanced fallback logic using exclusively AdMob
    if (!isLoaded && shouldShowFallback) {
      // Try AdMob Banner Fallback
      if (_admobFallbackLoadedStates[adId] == true) {
        debugPrint('✅ Showing AdMob Fallback Banner for ad ID: $adId');
        return _getAdMobFallbackWidget(adId);
      }
    } else if (!isLoaded) {
      debugPrint('Native ad not loaded, fallback conditions not met:');
      if (isLoaded) debugPrint('  - Native ad is loaded');
      if (!shouldShowFallback) debugPrint('  - Fallback is disabled');
    }

    if (!isLoaded || nativeAd == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ads_click, color: Colors.grey, size: 24),
            const SizedBox(height: 4),
            const Text(
              'Native Ad Loading...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Add refresh button for failed ads
            GestureDetector(
              onTap: () {
                loadNativeAdWithId(adId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Show fallback option - always available
            GestureDetector(
              onTap: () {
                debugPrint('🔄 Manual fallback trigger for ad: $adId');
                _nativeFallbackStates[adId] = true;
                _scheduleFallback(adId);
                _notifyAdStateChange();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Show Unity Ad',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Debug info
            Text(
              'Unity: ${_isUnityInitialized ? "✅" : "❌"} | Banner: ${_isBannerAdLoaded ? "✅" : "❌"}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 8,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Native ad content with enhanced error boundary
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  try {
                    debugPrint('🎯 Rendering AdWidget for native ad');
                    return Container(
                      color: Colors.white,
                      child: AdWidget(ad: nativeAd),
                    );
                  } catch (e) {
                    debugPrint('❌ Error rendering native ad: $e');
                    // Return fallback UI if ad rendering fails
                    return Container(
                      color: Colors.grey[50],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 24),
                            const SizedBox(height: 8),
                            const Text(
                              'Ad Display Error',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Error: ${e.toString()}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            // Close button for better UX
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  // Optionally track ad dismissal
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(179),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void disposeNativeAdWithId(String adId) {
    _nativeAds[adId]?.dispose();
    _nativeAds.remove(adId);
    _nativeAdLoadedStates.remove(adId);
  }

  void disposeAllNativeAds() {
    for (final ad in _nativeAds.values) {
      ad.dispose();
    }
    _nativeAds.clear();
    _nativeAdLoadedStates.clear();
  }

  /// Load AdMob banner ad specifically for swipeable carousel for a specific screen
  /// Uses LARGE_BANNER size for better visibility in the carousel
  Future<void> loadSwipeableBannerAd(String screenId,
      {int retryCount = 0}) async {
    if (kIsWeb) {
      debugPrint(
          '🌐 [SwipeableBanner] Skipping banner ad load on web platform');
      return;
    }

    const maxRetries = 2; // Maximum number of retry attempts
    final adKey = '${screenId}_banner';

    try {
      debugPrint(
          '🔄 [SwipeableBanner] Loading banner ad for screen: $screenId (Attempt ${retryCount + 1}/${maxRetries + 1})');

      // Dispose existing ad if any
      if (_swipeableBannerAds[adKey] != null) {
        debugPrint(
            '♻️ [SwipeableBanner] Disposing existing banner ad for key: $adKey');
        await _swipeableBannerAds[adKey]?.dispose();
        _swipeableBannerAds.remove(adKey);
      }

      _swipeableAdLoadedStates[adKey] = false;
      notifyListeners();

      // Get ad unit ID for AdMob
      final adUnitId = _getAdMobAdUnitId(screenId, 'banner');
      if (adUnitId.isEmpty) {
        debugPrint(
            '❌ [SwipeableBanner] Invalid AdMob banner ad unit ID for screen: $screenId');
        return;
      }

      debugPrint(
          '🎯 [SwipeableBanner] Creating LARGE_BANNER ad with ID: $adUnitId');

      // Create a new banner ad with LARGE_BANNER size for better visibility
      final bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.largeBanner, // 320x100
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint(
                '✅ [SwipeableBanner] Banner ad loaded successfully for screen: $screenId');
            _swipeableAdLoadedStates[adKey] = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
                '❌ [SwipeableBanner] Banner ad failed to load for screen: $screenId');
            debugPrint(
                '❌ [SwipeableBanner] Error code: ${error.code}, message: ${error.message}, domain: ${error.domain}');

            // Dispose the failed ad
            ad.dispose();
            _swipeableBannerAds.remove(adKey);
            _swipeableAdLoadedStates[adKey] = false;
            notifyListeners();

            // Retry loading if we haven't exceeded max retries
            if (retryCount < maxRetries) {
              final retryDelay = Duration(seconds: (retryCount + 1) * 2);
              debugPrint(
                  '⏳ [SwipeableBanner] Retrying in ${retryDelay.inSeconds} seconds...');
              Future.delayed(retryDelay, () {
                loadSwipeableBannerAd(screenId, retryCount: retryCount + 1);
              });
            } else {
              debugPrint(
                  '⚠️ [SwipeableBanner] Max retries ($maxRetries) reached for banner ad');
            }
          },
          onAdOpened: (ad) => debugPrint(
              'ℹ️ [SwipeableBanner] Banner ad opened for screen: $screenId'),
          onAdClosed: (ad) => debugPrint(
              'ℹ️ [SwipeableBanner] Banner ad closed for screen: $screenId'),
          onAdImpression: (ad) => debugPrint(
              '📊 [SwipeableBanner] Banner ad impression for screen: $screenId'),
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {
            debugPrint(
                '💰 [SwipeableBanner] Ad paid event: ${valueMicros / 1000000} $currencyCode');
          },
        ),
      );

      // Store the banner ad before loading
      _swipeableBannerAds[adKey] = bannerAd;
      _limitNativeAdCache();

      // Load the ad with a timeout
      debugPrint('⏳ [SwipeableBanner] Loading banner ad for screen: $screenId');
      await bannerAd.load().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint(
              '⚠️ [SwipeableBanner] Banner ad load timed out for screen: $screenId');
          throw TimeoutException('Banner ad load timed out');
        },
      );

      debugPrint(
          '✅ [SwipeableBanner] Banner ad load() completed for screen: $screenId');
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in loadSwipeableBannerAd: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get AdMob banner ad widget for swipeable carousel for a specific screen
  /// Returns a properly sized container with the banner ad or a fallback UI if the ad fails to load
  Widget getSwipeableBannerAd(String screenId) {
    final adKey = '${screenId}_banner';
    final bannerAd = _swipeableBannerAds[adKey];
    final isLoaded = _swipeableAdLoadedStates[adKey] ?? false;

    // Log the current state
    debugPrint('🔄 [SwipeableBanner] Getting banner ad for screen: $screenId');
    debugPrint('   - Banner ad instance: ${bannerAd != null}');
    debugPrint('   - Is loaded: $isLoaded');

    // If no banner ad instance exists, try to load one and return a placeholder
    if (bannerAd == null) {
      debugPrint(
          '⚠️ [SwipeableBanner] No banner ad instance found for screen: $screenId, loading...');
      // Schedule an ad load if not already loaded
      if (_swipeableAdLoadedStates[adKey] != true) {
        loadSwipeableBannerAd(screenId);
      }
      return _getBannerPlaceholder('Loading ad...');
    }

    // If the banner ad is not loaded yet, return a loading placeholder
    if (!isLoaded) {
      debugPrint(
          '⏳ [SwipeableBanner] Banner ad not loaded yet for screen: $screenId');
      return _getBannerPlaceholder('Loading ad...');
    }

    try {
      // Get the banner ad size, default to largeBanner dimensions if not available
      final width = bannerAd.size.width.toDouble();
      final height = bannerAd.size.height.toDouble();

      debugPrint(
          '✅ [SwipeableBanner] Returning banner ad widget for screen: $screenId');
      debugPrint('   - Size: ${width.toInt()}x${height.toInt()}');

      return Container(
        width: width,
        height: height,
        color: Colors.transparent, // Ensure background is transparent
        alignment: Alignment.center,
        child: AdWidget(ad: bannerAd),
      );
    } catch (e, stackTrace) {
      debugPrint(
          '❌ [SwipeableBanner] Error getting banner ad widget for screen $screenId: $e');
      debugPrint('Stack trace: $stackTrace');

      // Try to reload the ad if it fails
      if (e is Exception) {
        debugPrint(
            '🔄 [SwipeableBanner] Platform error, attempting to reload banner ad...');
        loadSwipeableBannerAd(screenId);
      }

      return _getBannerPlaceholder('Ad error');
    }
  }

  /// Load AdMob native ad specifically for swipeable carousel for a specific screen
  Future<void> loadSwipeableNativeAd(String screenId) async {
    if (kIsWeb) return;

    final adKey = '${screenId}_native';
    debugPrint('🔄 Loading swipeable native ad for screen: $screenId');

    try {
      // Dispose existing ad if any
      if (_swipeableNativeAds[adKey] != null) {
        debugPrint('♻️ Disposing existing native ad for $screenId');
        _swipeableNativeAds[adKey]?.dispose();
        _swipeableNativeAds.remove(adKey);
      }

      _swipeableAdLoadedStates[adKey] = false;
      notifyListeners();

      final adUnitId = _getAdMobAdUnitId(screenId, 'native');
      if (adUnitId.isEmpty) {
        debugPrint('❌ Invalid AdMob native ad unit ID for screen: $screenId');
        _handleSwipeableNativeAdLoadFailure(
            adKey, Exception('Invalid ad unit ID'));
        return;
      }

      debugPrint('🆔 Using ad unit ID: $adUnitId');

      final nativeAd = NativeAd(
        adUnitId: adUnitId,
        factoryId: 'adFactory',
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('✅ Native ad loaded successfully for screen: $screenId');
            _swipeableAdLoadedStates[adKey] = true;
            _nativeAdLoadCount++;
            _nativeAdFirstLoadTime ??= DateTime.now();
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
                '❌ Failed to load native ad for screen $screenId: $error');
            _swipeableAdLoadedStates[adKey] = false;
            ad.dispose();
            _swipeableNativeAds.remove(adKey);
            _handleSwipeableNativeAdLoadFailure(adKey, error);
          },
          onAdImpression: (ad) {
            debugPrint('👁️ Native ad impression for screen: $screenId');
            _nativeAdImpressionCount++;
          },
          onAdClicked: (ad) {
            debugPrint('👆 Native ad clicked for screen: $screenId');
            _nativeAdClickCount++;
          },
        ),
      );

      _swipeableNativeAds[adKey] = nativeAd;
      await nativeAd.load().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Native ad load timed out for screen: $screenId');
          _handleSwipeableNativeAdLoadFailure(
              adKey, TimeoutException('Native ad load timed out'));
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Exception in loadSwipeableNativeAd: $e');
      debugPrint('Stack trace: $stackTrace');
      _handleSwipeableNativeAdLoadFailure(adKey, e);
    }
  }

  /// Get AdMob native ad widget for swipeable carousel for a specific screen
  Widget? getSwipeableNativeAd(String screenId) {
    final adKey = '${screenId}_native';
    final nativeAd = _swipeableNativeAds[adKey];
    final isLoaded = _swipeableAdLoadedStates[adKey] ?? false;

    debugPrint('🔄 Getting native ad for screen: $screenId');
    debugPrint('   - Ad exists: ${nativeAd != null}');
    debugPrint('   - Is loaded: $isLoaded');

    if (nativeAd == null || !isLoaded) {
      // Try to reload the ad if it's not loaded
      if (nativeAd == null) {
        debugPrint('⚠️ No native ad found, scheduling reload...');
        Future.microtask(() => loadSwipeableNativeAd(screenId));
      }
      return null;
    }

    try {
      debugPrint('✅ Returning native ad widget for screen: $screenId');
      return AdWidget(ad: nativeAd);
    } catch (e) {
      debugPrint('❌ Error creating ad widget: $e');
      return null;
    }
  }

  // Note: Removed duplicate _handleNativeAdLoadFailure method
  // The implementation with the correct signature is kept below

  /// Handle swipeable native ad loading failure with retry logic
  void _handleSwipeableNativeAdLoadFailure(String adKey, dynamic error) {
    debugPrint('❌ Swipeable native ad load failed for key: $adKey');
    debugPrint('Error: $error');

    // Check if we should retry
    final retryCount = _nativeAdRetryCounts[adKey] ?? 0;
    final maxRetryAttempts = 3; // Maximum number of retry attempts

    if (retryCount < maxRetryAttempts) {
      final retryDelay =
          Duration(seconds: 2 * (retryCount + 1)); // Exponential backoff

      debugPrint(
          '🔄 Scheduling retry #${retryCount + 1} in ${retryDelay.inSeconds}s');

      _nativeAdRetryCounts[adKey] = retryCount + 1;

      // Schedule retry
      Future.delayed(retryDelay, () {
        if (_swipeableNativeAds.containsKey(adKey)) {
          debugPrint(
              '🔄 Retrying swipeable native ad load (attempt ${retryCount + 1}/$maxRetryAttempts)');
          final screenId = adKey.replaceAll('_native', '');
          loadSwipeableNativeAd(screenId);
        }
      });
    } else {
      debugPrint(
          '⚠️ Max retry attempts ($maxRetryAttempts) reached for swipeable native ad');
      _nativeAdRetryCounts.remove(adKey);

      // If we have Unity Ads fallback enabled, try to use it
      if (_isUnityInitialized) {
        debugPrint('🔄 Attempting to fall back to Unity Ads');
        // Extract screen ID from adKey (e.g., 'home_native' -> 'home')
        final screenId = adKey.replaceAll('_native', '');
        _scheduleFallback(
            '${screenId}_native'); // Pass the correct ad ID format
      }
    }

    // Update metrics
    _adFailures['native'] = (_adFailures['native'] ?? 0) + 1;
    _nativeAdFailCount++;
    notifyListeners();
  }

  /// Get AdMob ad unit ID based on screen and ad type
  String _getAdMobAdUnitId(String screenId, String adType) {
    if (kIsWeb) return '';

    final platform = Platform.isAndroid ? 'android' : 'ios';

    // Production ad unit IDs
    final Map<String, Map<String, String>> productionAdUnitIds = {
      'android': {
        'banner': 'ca-app-pub-3940256099942544/6300978111',
        'rewarded': 'ca-app-pub-3940256099942544/5224354917',
        'native': 'ca-app-pub-3940256099942544/2247696110',
      },
      'ios': {
        'banner': 'ca-app-pub-3940256099942544/2934735716',
        'rewarded': 'ca-app-pub-3940256099942544/1712485313',
        'native': 'ca-app-pub-3940256099942544/3986624511',
      },
    };

    // Use test ad unit IDs in debug mode or when forceTestMode is enabled
    if (kDebugMode || forceTestMode) {
      debugPrint(
          '⚠️ Using TEST ad unit IDs (${forceTestMode ? "forced" : "debug"} mode)');
      if (platform == 'android') {
        if (adType == 'native') {
          return 'ca-app-pub-3940256099942544/2247696110';
        } else if (adType == 'banner') {
          return 'ca-app-pub-3940256099942544/6300978111';
        } else if (adType == 'rewarded') {
          return 'ca-app-pub-3940256099942544/5224354917';
        } else if (adType == 'interstitial') {
          return 'ca-app-pub-3940256099942544/1033173712';
        }
      } else if (platform == 'ios') {
        if (adType == 'native') {
          return 'ca-app-pub-3940256099942544/3986624511';
        } else if (adType == 'banner') {
          return 'ca-app-pub-3940256099942544/2934735716';
        } else if (adType == 'rewarded') {
          return 'ca-app-pub-3940256099942544/1712485313';
        } else if (adType == 'interstitial') {
          return 'ca-app-pub-3940256099942544/4411468910';
        }
      }
    }

    // In release mode, use production ad unit IDs
    final adUnitId = productionAdUnitIds[platform]?[adType] ?? '';
    debugPrint('📱 Using $adType ad unit ID for $platform: $adUnitId');
    return adUnitId;
  }

  @override
  void dispose() {
    debugPrint('Disposing AdService resources');

    // Set disposed flag first to prevent any further operations
    _disposed = true;

    _bannerAdRefreshTimer?.cancel();
    _bannerAdRefreshTimer = null;

    // Dispose AdMob banner ad (legacy)
    _admobBannerAd?.dispose();
    _admobBannerAd = null;



    // Clear banner widget instance to prevent memory leaks
    _bannerWidgetInstance = null;
    debugPrint('🧹 Banner widget instance cleared');

    // AdMob native ad cleanup
    _nativeAd?.dispose();
    _nativeAd = null;

    // Dispose all native ads from the map
    for (final ad in _nativeAds.values) {
      try {
        ad.dispose();
      } catch (e) {
        debugPrint('Error disposing native ad: $e');
      }
    }
    _nativeAds.clear();
    _nativeAdLoadedStates.clear();
    _nativeFallbackStates.clear();

    // Dispose any pending timers
    for (final timer in _nativeAdTimers.values) {
      try {
        timer.cancel();
      } catch (e) {
        debugPrint('Error cancelling timer: $e');
      }
    }
    _nativeAdTimers.clear();

    // Cancel native ad refresh timer
    _nativeAdRefreshTimer?.cancel();
    _nativeAdRefreshTimer = null;

    _swipeableBannerAds.forEach((_, ad) => ad.dispose());
    _swipeableBannerAds.clear();
    _swipeableNativeAds.forEach((_, ad) => ad.dispose());
    _swipeableNativeAds.clear();
    
    // Call super.dispose() to properly clean up ChangeNotifier
    super.dispose();
    debugPrint('AdService resources disposed');
  }
  void _limitNativeAdCache() {
    // Limit standard native ads to 2
    if (_nativeAds.length > 2) {
      final oldestKey = _nativeAds.keys.first;
      _nativeAds[oldestKey]?.dispose();
      _nativeAds.remove(oldestKey);
      _nativeAdLoadedStates.remove(oldestKey);
      debugPrint('🧹 Cache limit reached, disposed native ad: $oldestKey');
    }
    
    // Limit swipeable native ads to 2
    if (_swipeableNativeAds.length > 2) {
      final oldestKey = _swipeableNativeAds.keys.first;
      _swipeableNativeAds[oldestKey]?.dispose();
      _swipeableNativeAds.remove(oldestKey);
      _swipeableAdLoadedStates.remove(oldestKey);
      debugPrint('🧹 Cache limit reached, disposed swipeable native ad: $oldestKey');
    }

    // Limit swipeable banner ads to 2
    if (_swipeableBannerAds.length > 2) {
      final oldestKey = _swipeableBannerAds.keys.first;
      _swipeableBannerAds[oldestKey]?.dispose();
      _swipeableBannerAds.remove(oldestKey);
      _swipeableAdLoadedStates.remove(oldestKey);
      debugPrint('🧹 Cache limit reached, disposed swipeable banner ad: $oldestKey');
    }
  }
}
