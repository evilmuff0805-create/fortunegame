import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_flow.dart';

class FortuneApp extends StatelessWidget {
  const FortuneApp({super.key, required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '운세 동물 컴패니언',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8C9A0)),
        useMaterial3: true,
      ),
      home: supabaseReady ? const _AppRouter() : const _OfflineNotice(),
    );
  }
}

/// 프로필 유무로 분기: 없음 → 온보딩, 있음 → 홈.
/// 온보딩 중간에 홈으로 채가지 않도록 reload는 "시작하기"(onComplete) 시점에만 호출.
class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return profile.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('프로필 로드 실패: $e', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (p) => p == null
          ? OnboardingFlow(
              onComplete: () => ref.read(profileProvider.notifier).reload(),
            )
          : HomeScreen(profile: p),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Supabase 설정이 없어 오프라인 골조 모드예요.\n'
            '--dart-define-from-file=dart_defines.json 으로 실행해줘.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
