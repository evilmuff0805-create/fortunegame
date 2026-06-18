import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../daily/grade_style.dart';

/// 카드 앨범 — 월별 그리드. 개봉일=등급 카드 / 미개봉·기록없음(과거)=빈 슬롯(회색).
/// 빈 슬롯은 협박 아닌 "채우고 싶다" 결(D5). opened_at 기준.
class AlbumScreen extends ConsumerStatefulWidget {
  const AlbumScreen({super.key});

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  late DateTime _month; // 해당 월 1일 (KST 기준)

  @override
  void initState() {
    super.initState();
    final kstNow = DateTime.now().toUtc().add(const Duration(hours: 9));
    _month = DateTime(kstNow.year, kstNow.month);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kstNow = DateTime.now().toUtc().add(const Duration(hours: 9));
    final isCurrentOrFuture = !_month.isBefore(DateTime(kstNow.year, kstNow.month));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1)),
            ),
            Text('${_month.year}년 ${_month.month}월', style: text.titleLarge),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              // 미래 달로는 못 감
              onPressed: isCurrentOrFuture
                  ? null
                  : () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _WeekdayHeader(),
        const SizedBox(height: 8),
        FutureBuilder<Map<int, ({String grade, bool opened})>>(
          future: ref
              .read(dailyRepositoryProvider)
              .month(_month.year, _month.month),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _Grid(month: _month, data: snap.data!, kstNow: kstNow);
          },
        ),
        const SizedBox(height: 16),
        Text('빈 칸은 봉투를 안 연 날이야. 오늘 것부터 차곡차곡 채워가자 🗂️',
            style: text.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();
  @override
  Widget build(BuildContext context) {
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Center(
              child: Text(d, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.month, required this.data, required this.kstNow});

  final DateTime month;
  final Map<int, ({String grade, bool opened})> data;
  final DateTime kstNow;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday % 7; // 일=0
    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isFuture = date.isAfter(DateTime(kstNow.year, kstNow.month, kstNow.day));
      final entry = data[day];
      cells.add(_DayCell(day: day, entry: entry, isFuture: isFuture));
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.entry, required this.isFuture});

  final int day;
  final ({String grade, bool opened})? entry;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    // 개봉일 = 등급 카드
    if (entry != null && entry!.opened) {
      final g = GradeStyle.of(entry!.grade);
      return GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('$day일 — ${g.emoji} ${g.label}'),
            content: Text(g.headline),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: g.color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(g.emoji, style: const TextStyle(fontSize: 20)),
        ),
      );
    }
    // 미래 = 빈칸(테두리만) / 과거 미개봉·무기록 = 회색 빈 슬롯
    return Container(
      decoration: BoxDecoration(
        color: isFuture ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: Text('$day',
          style: TextStyle(
              fontSize: 12,
              color: isFuture ? Colors.black38 : Colors.black26)),
    );
  }
}
