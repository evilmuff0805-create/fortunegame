import 'package:flutter/material.dart';

import '../../core/env.dart';
import '../../core/supabase_client.dart';

/// Slice 0 검증용 디버그 홈 — Slice 2에서 온보딩 화면으로 교체된다.
class DebugHomeScreen extends StatelessWidget {
  const DebugHomeScreen({super.key, required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    final uid = supabaseReady ? SupabaseBootstrap.currentUserId : null;
    return Scaffold(
      appBar: AppBar(title: const Text('운세 동물 컴패니언 — Slice 0')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusRow(
                label: 'Supabase 설정',
                ok: Env.hasSupabase,
                detail: Env.hasSupabase ? Env.supabaseUrl : '--dart-define 미주입',
              ),
              const SizedBox(height: 12),
              _StatusRow(
                label: '익명 인증',
                ok: uid != null,
                detail: uid ?? '세션 없음',
              ),
              const SizedBox(height: 12),
              _StatusRow(
                label: 'PostHog',
                ok: Env.hasPosthog,
                detail: Env.hasPosthog ? Env.posthogHost : 'no-op 모드',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ok, required this.detail});

  final String label;
  final bool ok;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.cancel,
          color: ok ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
