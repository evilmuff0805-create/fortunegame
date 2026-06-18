import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/profile.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/providers.dart';
import '../album/album_screen.dart';
import '../dressup/dressup_screen.dart';
import 'home_screen.dart';

/// 온보딩 후 메인 셸 — 하단 탭(홈/꾸미기/앨범).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.profile});
  final Profile profile;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _titles = ['내 동물', '꾸미기', '앨범'];

  Future<void> _pushSettings() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: '아침 알림 시간',
    );
    if (time == null) return;
    await NotificationService.instance.requestPermission();
    await NotificationService.instance.scheduleDailyMorning(time);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('매일 ${time.format(context)}에 봉투 알림을 보낼게')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(animalCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          if (_index == 0)
            IconButton(
              icon: const Icon(Icons.notifications_none),
              tooltip: '아침 알림',
              onPressed: _pushSettings,
            ),
        ],
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('카탈로그 로드 실패: $e')),
        data: (map) {
          final animal = map[widget.profile.animalId];
          return IndexedStack(
            index: _index,
            children: [
              HomeScreen(profile: widget.profile),
              if (animal != null)
                DressupScreen(animal: animal)
              else
                const Center(child: Text('동물 정보 없음')),
              const AlbumScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.checkroom_outlined), selectedIcon: Icon(Icons.checkroom), label: '꾸미기'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: '앨범'),
        ],
      ),
    );
  }
}
