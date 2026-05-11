import 'dart:io' show Platform;

import 'package:bitcoin_cloud_mining/config/api_config.dart';
import 'package:bitcoin_cloud_mining/firebase_options.dart';
import 'package:bitcoin_cloud_mining/models/notification.dart' as model;
import 'package:bitcoin_cloud_mining/providers/auth_provider.dart';
import 'package:bitcoin_cloud_mining/providers/network_provider.dart';
import 'package:bitcoin_cloud_mining/providers/notification_provider.dart';
import 'package:bitcoin_cloud_mining/providers/reward_provider.dart';
import 'package:bitcoin_cloud_mining/providers/wallet_provider.dart';
import 'package:bitcoin_cloud_mining/screens/launch_screen.dart';
import 'package:bitcoin_cloud_mining/screens/loading_user_data_screen.dart';
import 'package:bitcoin_cloud_mining/screens/navigation_screen.dart';
import 'package:bitcoin_cloud_mining/screens/notification_screen.dart';
import 'package:bitcoin_cloud_mining/screens/wallet_screen.dart';
import 'package:bitcoin_cloud_mining/services/analytics_service.dart';
import 'package:bitcoin_cloud_mining/services/api_service.dart';
import 'package:bitcoin_cloud_mining/services/mining_notification_service.dart';
import 'package:bitcoin_cloud_mining/services/network_service.dart';
import 'package:bitcoin_cloud_mining/services/notification_service.dart';
import 'package:bitcoin_cloud_mining/utils/enums.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:window_manager/window_manager.dart';
import 'package:workmanager/workmanager.dart';

import 'config/mediation_config.dart';
import 'fcm_service.dart';
import 'services/audio_service.dart';
import 'services/sound_notification_service.dart';
import 'utils/app_logger.dart';
import 'utils/storage_utils.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
}

/// Initialize mobile-only services in parallel - non-critical, don't block startup
void _initMobileServices() {
  // Unity Ads
  try {
    final gameId = Platform.isAndroid ? '5916099' : '5916098';
    UnityAds.init(
      gameId: gameId,
      testMode: false,
      onComplete: () {},
      onFailed: (error, message) {},
    );
  } catch (e) {
    AppLogger.error('Unity Ads init failed', error: e);
  }

  // AdMob + mediation
  try {
    MobileAds.instance.initialize();
    MobileAds.instance
        .updateRequestConfiguration(
          RequestConfiguration(
            maxAdContentRating: MaxAdContentRating.pg,
            tagForChildDirectedTreatment:
                TagForChildDirectedTreatment.unspecified,
            tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
            testDeviceIds: MediationConfig.enableTestDevices
                ? MediationConfig.testDeviceIds
                : null,
          ),
        )
        .catchError((_) {});
  } catch (e) {
    AppLogger.error('AdMob init failed', error: e);
  }

  // Workmanager
  try {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  } catch (e, stackTrace) {
    AppLogger.error('Workmanager init failed',
        error: e, stackTrace: stackTrace);
  }

  // Window manager (desktop only)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      windowManager.ensureInitialized().then((_) {
        const windowOptions = WindowOptions(
          size: Size(800, 600),
          minimumSize: Size(800, 600),
          backgroundColor: Colors.transparent,
          title: 'Bitcoin Mining Pro',
          titleBarStyle: TitleBarStyle.normal,
        );
        windowManager.waitUntilReadyToShow(windowOptions).then((_) {
          windowManager.show();
          windowManager.focus();
          windowManager.setPreventClose(true);
        });
      });
    } catch (e, stackTrace) {
      AppLogger.error('Window manager init failed',
          error: e, stackTrace: stackTrace);
    }
  }
}

void main() async {
  // Set zone error handling to non-fatal
  // BindingBase.debugZoneErrorsAreFatal = false; // Optional: Debug zone errors ko ignore na karein

  // Ensure Flutter bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Preload fonts to prevent font loading issues
  await GoogleFonts.pendingFonts([
    GoogleFonts.notoSans(),
    GoogleFonts.poppins(),
  ]);

  // Initialize Firebase with proper configuration
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Set up background message handler (non-blocking)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Run non-critical Firebase services in parallel (don't block startup)
    Future.wait([
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true),
      AnalyticsService.trackAppOpen(),
      FcmService.initializeFCM(),
    ]).catchError((e) {
      AppLogger.error('Non-critical Firebase services init failed', error: e);
      return <Future>[];
    });

    // Crashlytics initialization
    try {
      // Check if Crashlytics is available before initializing
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      };
      AppLogger.info('Crashlytics initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Crashlytics initialization failed',
          error: e, stackTrace: stackTrace);
      // Continue without crashlytics if it fails
      FlutterError.onError = (errorDetails) {
        // Fallback error logging
        AppLogger.error('Flutter error',
            error: errorDetails.exception, stackTrace: errorDetails.stack);
      };
    }
  } catch (e, stackTrace) {
    AppLogger.error('Firebase initialization failed',
        error: e, stackTrace: stackTrace);
  }

  // Initialize ad SDKs and background tasks in parallel (non-blocking)
  if (!kIsWeb) {
    // All these are independent - run them without awaiting
    _initMobileServices();
  }

  // Initialize services
  final apiService = ApiService();
  final notificationService = NotificationService(
      baseUrl: kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000',
      apiService: apiService);

  // Run the app
  try {
    runApp(MyApp(
      apiService: apiService,
      notificationService: notificationService,
    ));
  } catch (e, stackTrace) {
    AppLogger.error('App runApp failed', error: e, stackTrace: stackTrace);
  }
}

class MyApp extends StatefulWidget {
  final ApiService apiService;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.apiService,
    required this.notificationService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
    with WindowListener, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    // Run FCM setup in background - don't block UI
    _setupFCM();
    _setupNotificationListeners();
  }

  Future<void> _setupFCM() async {
    try {
      // Get token without blocking - fire and forget
      FcmService.getFcmToken().then((token) {
        if (token != null) {
          sendTokenToBackend(token);
        }
      });
      FcmService.listenFCM();

      // Initialize mining and sound notification services (non-blocking)
      MiningNotificationService.initialize().catchError((_) {});
      SoundNotificationService.initialize().catchError((_) {});
    } catch (e, stackTrace) {
      AppLogger.error('FCM setup failed', error: e, stackTrace: stackTrace);
    }
  }

  void _setupNotificationListeners() {
    // Listen for local notification taps
    widget.notificationService.selectNotificationSubject.listen((payload) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Navigate to notification screen instead of just adding to provider
        Navigator.of(context).pushNamed('/notifications');

        // Also add to provider for display
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);
        final notification = model.Notification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Local Notification',
          body: payload ?? '',
          status: 'unread',
          timestamp: DateTime.now(),
          category: NotificationCategory.system,
          payload: payload,
        );
        provider.addNotificationFromLocal(notification);
      }
    });

    // Listen for FCM foreground messages (only if Firebase is available)
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          // Navigate to notification screen for FCM messages too
          Navigator.of(context).pushNamed('/notifications');

          final provider =
              Provider.of<NotificationProvider>(context, listen: false);
          final notification = model.Notification(
            id: message.messageId ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            title: message.notification?.title ?? 'Push Notification',
            body: message.notification?.body ?? '',
            status: 'unread',
            timestamp: DateTime.now(),
            category: NotificationCategory.system,
            payload: message.data['payload'],
          );
          provider.addNotificationFromLocal(notification);
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('FCM foreground message listener failed',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> sendTokenToBackend(String token) async {
    try {
      final jwtToken = await StorageUtils.getToken();

      // Only send FCM token if user is logged in
      if (jwtToken == null || jwtToken.isEmpty) {
        return;
      }

      final url = Uri.parse(ApiConfig.fcmTokenUrl);
      final headers = ApiConfig.getHeaders(token: jwtToken);

      final response = await http.post(
        url,
        headers: headers,
        body: '{"fcmToken": "$token"}',
      );

      if (response.statusCode == 200) {
        // FCM token updated successfully
      } else {
        // Failed to update FCM token
      }
    } catch (e) {
      // Error updating FCM token
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    // Dispose audio service
    AudioService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final walletProvider = navigatorKey.currentContext != null
        ? Provider.of<WalletProvider>(navigatorKey.currentContext!,
            listen: false)
        : null;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App background me gaya, network check band karo
      NetworkService().pausePeriodicCheck();
      if (walletProvider != null) walletProvider.isAppInBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      // App wapas aayi, network check fir se start karo
      NetworkService().resumePeriodicCheck();
      if (walletProvider != null) walletProvider.isAppInBackground = false;
    }
  }

  @override
  void onWindowEvent(String eventName) {}

  @override
  void onWindowClose() async {
    final bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if (!mounted) return;
      final bool? shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm close'),
            content: const Text('Are you sure you want to close the app?'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      if (shouldClose == true) {
        await windowManager.destroy();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WalletProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RewardProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
              notificationService: widget.notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) => NetworkProvider(),
        ),
        Provider.value(value: widget.apiService),
        Provider.value(value: widget.notificationService),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Bitcoin Mining Pro',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansTextTheme().merge(
            TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Poppins'),
              bodyMedium: TextStyle(fontFamily: 'Poppins'),
              displayLarge: TextStyle(fontFamily: 'Poppins'),
              displayMedium: TextStyle(fontFamily: 'Poppins'),
              displaySmall: TextStyle(fontFamily: 'Poppins'),
              headlineLarge: TextStyle(fontFamily: 'Poppins'),
              headlineMedium: TextStyle(fontFamily: 'Poppins'),
              headlineSmall: TextStyle(fontFamily: 'Poppins'),
              titleLarge: TextStyle(fontFamily: 'Poppins'),
              titleMedium: TextStyle(fontFamily: 'Poppins'),
              titleSmall: TextStyle(fontFamily: 'Poppins'),
              labelLarge: TextStyle(fontFamily: 'Poppins'),
              labelMedium: TextStyle(fontFamily: 'Poppins'),
              labelSmall: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ),
        initialRoute: '/launch',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        ],
        routes: {
          '/': (context) => const LaunchScreen(),
          '/launch': (context) => const LaunchScreen(),
          '/loading': (context) => const LoadingUserDataScreen(),
          '/wallet': (context) => const WalletScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/navigation': (context) => const NavigationScreen(),
        },
      ),
    );
  }
}
