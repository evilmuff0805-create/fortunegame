import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/item.dart';

/// 오늘 봉투 상태 (today-fortune). 미개봉이면 등급은 숨겨지고 누설 티어만 온다(①).
class DailyStatus {
  const DailyStatus({
    required this.date,
    required this.animalId,
    required this.opened,
    required this.leak,
    this.grade,
    this.message,
  });

  final String date;
  final String animalId;
  final bool opened;
  final String leak; // 'none' | 'radiant' | 'rainbow'
  final String? grade; // opened일 때만
  final String? message;

  factory DailyStatus.fromJson(Map<String, dynamic> j) => DailyStatus(
        date: j['date'] as String,
        animalId: j['animalId'] as String,
        opened: j['opened'] as bool,
        leak: j['leak'] as String? ?? 'none',
        grade: j['grade'] as String?,
        message: j['message'] as String?,
      );
}

/// 개봉 결과 (open-pack). 서버 권위 — 등급·보상·스트릭 확정.
class OpenResult {
  const OpenResult({
    required this.grade,
    required this.scores,
    required this.message,
    required this.rewardItemId,
    required this.streakCurrent,
    required this.streakLongest,
    required this.justOpened,
  });

  final String grade;
  final Map<String, int> scores;
  final String? message;
  final String? rewardItemId;
  final int streakCurrent;
  final int streakLongest;
  final bool justOpened;

  factory OpenResult.fromJson(Map<String, dynamic> j) => OpenResult(
        grade: j['grade'] as String,
        scores: {
          for (final e in (j['scores'] as Map).entries)
            e.key as String: (e.value as num).toInt()
        },
        message: j['message'] as String?,
        rewardItemId: j['rewardItemId'] as String?,
        streakCurrent: (j['streak']?['current'] as num?)?.toInt() ?? 1,
        streakLongest: (j['streak']?['longest'] as num?)?.toInt() ?? 1,
        justOpened: j['justOpened'] as bool? ?? false,
      );
}

class DailyRepository {
  DailyRepository(this._client);
  final SupabaseClient _client;

  Future<DailyStatus> status() async {
    final res = await _client.functions.invoke('today-fortune', body: {});
    _check(res, 'today-fortune');
    return DailyStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OpenResult> open() async {
    final res = await _client.functions.invoke('open-pack', body: {});
    _check(res, 'open-pack');
    return OpenResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// 한 달치 운세 기록 (앨범). day(1~31) → (grade, opened). RLS read own.
  Future<Map<int, ({String grade, bool opened})>> month(int year, int month) async {
    String two(int n) => n.toString().padLeft(2, '0');
    final first = '$year-${two(month)}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final last = '$year-${two(month)}-${two(lastDay)}';
    final rows = await _client
        .from('daily_fortunes')
        .select('date, grade, opened_at')
        .gte('date', first)
        .lte('date', last);
    final map = <int, ({String grade, bool opened})>{};
    for (final r in rows) {
      final day = int.parse((r['date'] as String).split('-')[2]);
      map[day] = (grade: r['grade'] as String, opened: r['opened_at'] != null);
    }
    return map;
  }

  /// 보상 아이템 메타 (없으면 null).
  Future<Item?> item(String id) async {
    final row = await _client
        .from('items')
        .select('id, type, asset_key')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Item.fromRow(row);
  }

  void _check(FunctionResponse res, String name) {
    if (res.status != 200) {
      final msg = (res.data is Map ? (res.data as Map)['error'] : null) ?? res.status;
      throw Exception('$name 실패: $msg');
    }
  }
}
