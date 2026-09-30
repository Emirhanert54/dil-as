import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../repositories/child_profile_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _mainChannel =
  AndroidNotificationChannel(
    'dilas_main_channel',
    'DİL-AS Bildirimleri',
    description: 'Ödev, mesaj ve genel DİL-AS bildirimleri',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _dailyChannel =
  AndroidNotificationChannel(
    'dilas_daily_channel',
    'Günlük Hatırlatmalar',
    description: 'DİL-AS günlük çalışma hatırlatmaları',
    importance: Importance.high,
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    await _requestPermissions();
    await _initLocalNotifications();
    await _createAndroidChannels();

    await _subscribeDefaultTopics();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedFromPush);

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      await _handleMessageTap(initialMessage);
    }

    await saveTokenForCurrentUser();

    _messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });

    await scheduleMotivationReminders();
  }

  Future<void> _subscribeDefaultTopics() async {
    try {
      await _messaging.subscribeToTopic('dilas_all_users');
    } catch (_) {}
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidPlugin =
    _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _local.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;

        if (payload == null) return;

        await _handleLocalPayload(payload);
      },
    );
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin =
    _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_mainChannel);
    await androidPlugin?.createNotificationChannel(_dailyChannel);
  }

  Future<void> saveTokenForCurrentUser() async {
    final token = await _messaging.getToken();

    if (token == null || token.trim().isEmpty) return;

    await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    final firestore = FirebaseFirestore.instance;

    String? childId;

    try {
      childId = await ChildProfileRepository.ensureActiveChildProfile();
    } catch (_) {
      childId = null;
    }

    final tokenData = {
      'token': token,
      'uid': uid,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set(
      tokenData,
      SetOptions(merge: true),
    );

    if (childId != null && childId.trim().isNotEmpty) {
      await firestore
          .collection('childProfiles')
          .doc(childId)
          .collection('fcmTokens')
          .doc(token)
          .set(
        {
          ...tokenData,
          'childId': childId,
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;

    final title = notification?.title ??
        message.data['title']?.toString() ??
        'DİL-AS';

    final body = notification?.body ??
        message.data['body']?.toString() ??
        'Yeni bildirimin var.';

    final type = message.data['type']?.toString() ?? 'general';
    final rewardId = message.data['rewardId']?.toString();

    final payload = _createPayload(
      type: type,
      rewardId: rewardId,
    );

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _mainChannel.id,
          _mainChannel.name,
          channelDescription: _mainChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _onOpenedFromPush(RemoteMessage message) async {
    await _handleMessageTap(message);
  }

  Future<void> _handleMessageTap(RemoteMessage message) async {
    final type = message.data['type']?.toString() ?? 'general';
    final rewardId = message.data['rewardId']?.toString();

    if (type == 'daily') {
      return;
    }

    if (type == 'message' && rewardId != null && rewardId.trim().isNotEmpty) {
      await giveNotificationStarOnce(
        rewardId: rewardId,
        reason: 'message_open',
      );
    }
  }

  Future<void> _handleLocalPayload(String payload) async {
    final data = _parsePayload(payload);
    final type = data['type'];
    final rewardId = data['rewardId'];

    if (type == 'daily') {
      return;
    }

    if (type == 'message' && rewardId != null && rewardId.trim().isNotEmpty) {
      await giveNotificationStarOnce(
        rewardId: rewardId,
        reason: 'message_open',
      );
    }
  }

  Future<void> scheduleMotivationReminders() async {
    // Otomatik teşvik bildirimleri:
    // Günde en fazla 3 tane olacak: 09:00 / 17:00 / 21:00.
    // Uygulama her açıldığında eski planları temizleyip 30 gün ileriye yeniden kurar.
    // Manuel Firebase topic bildirimi bundan bağımsızdır, ona sınır koymaz.

    for (int id = 300000; id <= 300120; id++) {
      await _local.cancel(id: id);
    }

    // Eski test / eski sistem ID'lerini temizle
    await _local.cancel(id: 202406);
    await _local.cancel(id: 202407);
    await _local.cancel(id: 202408);
    await _local.cancel(id: 909090);

    final now = tz.TZDateTime.now(tz.local);

    final reminders = [
      {
        'hour': 9,
        'minute': 0,
        'title': 'Günaydın! DİL-AS seni bekliyor 🌟',
        'body': 'Bugün kısa bir etkinlik yapıp öğrenmeye başlayabilirsin.',
      },
      {
        'hour': 17,
        'minute': 0,
        'title': 'Bugün harika gidiyorsun 🚀',
        'body': 'Bir mini oyun oynayıp yıldızlarını artırmaya ne dersin?',
      },
      {
        'hour': 21,
        'minute': 0,
        'title': 'Kısa bir tekrar zamanı 📚',
        'body': 'DİL-AS’ta birkaç dakikalık çalışma bile çok şey kazandırır.',
      },
    ];

    int notificationId = 300000;

    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final targetDay = now.add(Duration(days: dayOffset));

      for (final reminder in reminders) {
        final scheduledTime = tz.TZDateTime(
          tz.local,
          targetDay.year,
          targetDay.month,
          targetDay.day,
          reminder['hour'] as int,
          reminder['minute'] as int,
        );

        if (scheduledTime.isBefore(now)) {
          continue;
        }

        await _scheduleMotivationReminder(
          id: notificationId,
          scheduledTime: scheduledTime,
          title: reminder['title'] as String,
          body: reminder['body'] as String,
        );

        notificationId++;
      }
    }

    final pending = await _local.pendingNotificationRequests();

    debugPrint(
      'DİL-AS teşvik bildirimleri planlandı. Bekleyen bildirim sayısı: ${pending.length}',
    );
  }

  Future<void> _scheduleMotivationReminder({
    required int id,
    required tz.TZDateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    await _local.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannel.id,
          _dailyChannel.name,
          channelDescription: _dailyChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _createPayload(
        type: 'daily',
        rewardId: '',
      ),
    );
  }

  Future<bool> giveNotificationStarOnce({
    required String rewardId,
    required String reason,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return false;

    final firestore = FirebaseFirestore.instance;

    String? childId;

    try {
      childId = await ChildProfileRepository.ensureActiveChildProfile();
    } catch (_) {
      childId = null;
    }

    final userRef = firestore.collection('users').doc(uid);
    final rewardRef = userRef.collection('notificationRewards').doc(rewardId);

    var rewardGiven = false;

    await firestore.runTransaction((transaction) async {
      final rewardSnap = await transaction.get(rewardRef);

      if (rewardSnap.exists) {
        rewardGiven = false;
        return;
      }

      rewardGiven = true;

      transaction.set(rewardRef, {
        'rewardId': rewardId,
        'reason': reason,
        'stars': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        userRef,
        {
          'stars': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (childId != null && childId.trim().isNotEmpty) {
        final childRef = firestore.collection('childProfiles').doc(childId);

        transaction.set(
          childRef,
          {
            'stars': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    return rewardGiven;
  }

  String _createPayload({
    required String type,
    String? rewardId,
  }) {
    return 'type=$type;rewardId=${rewardId ?? ''}';
  }

  Map<String, String> _parsePayload(String payload) {
    final result = <String, String>{};

    final parts = payload.split(';');

    for (final part in parts) {
      final index = part.indexOf('=');

      if (index == -1) continue;

      final key = part.substring(0, index);
      final value = part.substring(index + 1);

      if (key.trim().isEmpty || value.trim().isEmpty) continue;

      result[key] = value;
    }

    return result;
  }
}