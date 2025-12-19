import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../shared/utils/platform_helper.dart';
import '../models/app_notification.dart';

class NotificationsService {
  static const String notificationsBoxName = 'notifications_box';

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(initSettings);

    _initialized = true;
  }

  static Future<void> requestPermissionsIfNeeded() async {
    if (!PlatformHelper.isMobile) return;

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Box<AppNotification> get box => Hive.box<AppNotification>(notificationsBoxName);

  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(notificationsBoxName)) {
      await Hive.openBox<AppNotification>(notificationsBoxName);
    }
  }

  static int generateNotificationId() {
    final rng = Random();
    int id;
    do {
      id = rng.nextInt(1 << 31);
    } while (box.values.any((n) => n.notificationId == id));
    return id;
  }

  static tz.TZDateTime _nextInstanceOfTime(int timeMinutes) {
    final now = tz.TZDateTime.now(tz.local);
    final target = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeMinutes ~/ 60,
      timeMinutes % 60,
    );
    if (target.isAfter(now)) return target;
    return target.add(const Duration(days: 1));
  }

  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, int timeMinutes) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeMinutes ~/ 60,
      timeMinutes % 60,
    );

    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static NotificationDetails _details() {
    const androidDetails = AndroidNotificationDetails(
      'daily_notifications',
      'Daily notifications',
      channelDescription: 'Reminders scheduled by the Notifications app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  static Future<void> schedule(AppNotification notification) async {
    await initialize();

    await cancel(notification);

    if (!notification.enabled) return;

    // Disregard Windows: the plugin supports it, but repeating limitations exist.
    if (!PlatformHelper.isMobile && !PlatformHelper.isDesktop) return;

    try {
      if (notification.scheduleType == NotificationScheduleType.daily) {
        await _plugin.zonedSchedule(
          notification.notificationId,
          notification.title,
          notification.body,
          _nextInstanceOfTime(notification.timeMinutes),
          _details(),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: notification.id,
        );
      } else {
        // Weekly: schedule one per weekday. We allocate derived IDs.
        for (final weekday in notification.weekdays.toSet()) {
          final derivedId = _derivedNotificationId(notification.notificationId, weekday);
          await _plugin.zonedSchedule(
            derivedId,
            notification.title,
            notification.body,
            _nextInstanceOfWeekday(weekday, notification.timeMinutes),
            _details(),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: notification.id,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationsService.schedule: failed $e');
      }
    }
  }

  static int _derivedNotificationId(int base, int weekday) {
    // Keep IDs stable and distinct: base in high range, offset by weekday.
    // Weekday is 1..7.
    final safeBase = base & 0x7FFFFFF8;
    return safeBase + (weekday.clamp(1, 7));
  }

  static Future<void> cancel(AppNotification notification) async {
    await initialize();

    await _plugin.cancel(notification.notificationId);
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(_derivedNotificationId(notification.notificationId, weekday));
    }
  }

  static Future<void> rescheduleAll() async {
    await initialize();
    await openBox();

    for (final notification in box.values) {
      await schedule(notification);
    }
  }

  static Future<void> upsert(AppNotification notification) async {
    await openBox();

    await box.put(notification.id, notification);
    await schedule(notification);
  }

  static Future<void> delete(AppNotification notification) async {
    await openBox();

    await cancel(notification);
    await box.delete(notification.id);
  }
}
