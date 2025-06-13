import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications_plus/flutter_local_notifications_plus.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';
import 'NotificationPlugin.dart';
//
// class ReceivedNotification {
//   ReceivedNotification({
//     required this.id,
//     required this.title,
//     required this.body,
//     required this.payload,
//   });
//
//   final int id;
//   final String title;
//   final String body;
//   final String payload;
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications_plus/flutter_local_notifications_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart'; // for didReceiveLocalNotificationSubject, selectNotificationSubject, ReceivedNotification

class LocalNotification {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  static final DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: true,
    onDidReceiveLocalNotification: (
        int id,
        String? title,
        String? body,
        String? payload,
        ) =>
        didReceiveLocalNotificationSubject.add(
          ReceivedNotification(
            id: id,
            title: title!,
            body: body!,
            payload: payload!,
          ),
        ),
  );

  static const DarwinInitializationSettings initializationSettingsMacOS =
  DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
    macOS: initializationSettingsMacOS,
  );

  /// Call this once at app startup
  Future<void> initialize() async {
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) async {
        selectedNotificationPayload = payload.toString();
        selectNotificationSubject.add(payload.toString());
      },
    );

    // Schedule the two default notifications:
    await scheduleDaily(
      1,
      'Morning Meditation Reminder',
      'Have you logged in to practice your morning meditation today?',
      const TimeOfDay(hour: 8, minute: 0),
    );
    await scheduleDaily(
      2,
      'Bedtime Meditation Reminder',
      'Have you logged in to practice your bedtime meditation today?',
      const TimeOfDay(hour: 20, minute: 0),
    );
  }

  /// Schedules (or reschedules) a daily notification at [time].
  Future<void> scheduleDaily(
      int id,
      String title,
      String body,
      TimeOfDay time,
      ) async {
    // Cancel any existing notification with this id
    await flutterLocalNotificationsPlugin.cancel(id);

    final androidDetails = AndroidNotificationDetails(
      'daily_channel_$id',
      'Daily Notifications',
      channelDescription: 'Daily reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails();
    final platformDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time.hour, time.minute),
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Computes the next occurrence of today at [hour]:[minute], or tomorrow if already passed.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Request permissions on iOS/macOS
  void requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Handle iOS foreground notifications
  void configureDidReceiveLocalNotificationSubject(BuildContext context) {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body)
              : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {},
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }

  /// Handle notification taps
  void configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String? payload) async {
      // Navigate or handle payload
    });
  }

  Future<void> showDailyAtTime() async {
    // morning
    await scheduleDaily(
      1,
      'Morning Meditation Reminder',
      'Have you logged in to practice your morning meditation today?',
      const TimeOfDay(hour: 8, minute: 0),
    );
    // evening
    await scheduleDaily(
      2,
      'Bedtime Meditation Reminder',
      'Have you logged in to practice your bedtime meditation today?',
      const TimeOfDay(hour: 20, minute: 0),
    );
  }
}
