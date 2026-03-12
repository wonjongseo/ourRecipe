import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const int cookingDoneNotificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      ),
    );

    await _plugin.initialize(settings);
    await requestPermission();
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'cooking_done_channel',
      'cooking_done_channel_name',
      channelDescription: 'cooking_done',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    ),
  );

  Future<void> scheduleCookingDoneNotification(Duration delay) async {
    if (delay <= Duration.zero) return;
    await _plugin.zonedSchedule(
      cookingDoneNotificationId,
      AppStrings.appTitle.tr,
      AppStrings.cookingCompleted.tr,
      tz.TZDateTime.now(tz.local).add(delay),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showCookingDoneNotification() async {
    await _plugin.show(
      cookingDoneNotificationId,
      AppStrings.appTitle.tr,
      AppStrings.cookingCompleted.tr,
      _notificationDetails,
    );
  }

  Future<void> cancelCookingDoneNotification() async {
    await _plugin.cancel(cookingDoneNotificationId);
  }
}
