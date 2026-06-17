import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 아침 로컬 푸시 (시간 설정 가능). 협박·죄책감 문구 금지(D5).
/// 실제 전달은 실기기 검증(컨테이너 불가). 매일 같은 시각 반복.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'daily_fortune';
  static const _notiId = 1001;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul')); // KST 고정
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// 매일 [time]에 반복 알림. 협박 없는 따뜻한 카피.
  Future<void> scheduleDailyMorning(TimeOfDay time) async {
    if (!_ready) return;
    await _plugin.cancel(_notiId);
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      _notiId,
      '오늘의 봉투가 도착했어 🐾',
      '내 동물이 운세 카드를 건네러 왔어. 천천히 열어봐.',
      first,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, '데일리 운세',
          channelDescription: '아침마다 오늘의 운세 봉투 알림',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );
  }

  Future<void> cancelDaily() => _plugin.cancel(_notiId);
}
