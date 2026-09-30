import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'pages/auth_gate.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'services/ad_manager.dart';
import 'services/idle_ad_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- ADMOB (REKLAM) BAŞLATMA VE ÇOCUK FİLTRESİ ---
  await MobileAds.instance.initialize();

  // DİL-AS İlkokul Çocukları Filtresi (COPPA) - KESİNLİKLE SİLİNMEMELİ
  RequestConfiguration requestConfiguration = RequestConfiguration(
    tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
    maxAdContentRating: MaxAdContentRating.g, // Sadece Genel İzleyici reklamları
  );
  await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

  await AdManager.initializeSettings();

  // Firebase ve Bildirimler
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();

  // --- REVENUECAT (PREMIUM) KURULUMU ---
  await Purchases.setLogLevel(LogLevel.debug);
  if (Platform.isAndroid) {
    PurchasesConfiguration configuration = PurchasesConfiguration("goog_idaSlTGhtMVwvisOVQGuqBRBwRN");
    await Purchases.configure(configuration);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const IdleAdWrapper(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'DİL-AS',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return _OrientationGate(
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
        ),
        useMaterial3: true,
        fontFamily: null,
      ),
      home: const AuthGate(),
    );
  }
}

class _OrientationGate extends StatefulWidget {
  final Widget child;
  const _OrientationGate({required this.child});
  @override
  State<_OrientationGate> createState() => _OrientationGateState();
}

class _OrientationGateState extends State<_OrientationGate> {
  String? _lastMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final isTablet = shortestSide >= 600;
    final nextMode = isTablet ? "tablet" : "phone";

    if (_lastMode == nextMode) return;
    _lastMode = nextMode;

    if (isTablet) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}