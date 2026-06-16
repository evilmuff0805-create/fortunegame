import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// 익명 → 이메일 승격 (D1: 기기 분실 시 동물 복원).
/// Google/Apple은 자리만(비활성) — 네이티브 설정은 실기기 단계로 이연.
class AccountLinkSheet extends ConsumerStatefulWidget {
  const AccountLinkSheet({super.key});

  @override
  ConsumerState<AccountLinkSheet> createState() => _AccountLinkSheetState();
}

enum _Phase { email, otp }

class _AccountLinkSheetState extends ConsumerState<AccountLinkSheet> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  _Phase _phase = _Phase.email;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    final repo = ref.read(onboardingRepositoryProvider);
    await _run(() async {
      await repo.sendEmailUpgrade(_emailCtrl.text.trim());
      if (mounted) setState(() => _phase = _Phase.otp);
    });
  }

  Future<void> _verify() async {
    final repo = ref.read(onboardingRepositoryProvider);
    await _run(() async {
      await repo.verifyEmailOtp(
        email: _emailCtrl.text.trim(),
        token: _otpCtrl.text.trim(),
      );
      // 같은 uid 유지 → 프로필 행 불변(동물 보존). reload 불필요.
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('계정 연결로 동물 지키기', style: text.titleLarge),
          const SizedBox(height: 4),
          Text('기기를 잃어버려도 이메일로 다시 만날 수 있어', style: text.bodyMedium),
          const SizedBox(height: 20),

          if (_phase == _Phase.email) ...[
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'you@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _sendCode,
              child: _busy
                  ? const _Spinner()
                  : const Text('인증 코드 받기'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('또는', style: text.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            // OAuth 자리만 — 네이티브 설정 실기기 이연 (todo/lessons 기록)
            _DisabledOAuthButton(label: 'Google로 계속 (준비 중)'),
            const SizedBox(height: 8),
            _DisabledOAuthButton(label: 'Apple로 계속 (준비 중)'),
          ] else if (_phase == _Phase.otp) ...[
            Text('${_emailCtrl.text.trim()} 로 보낸 코드를 입력해줘', style: text.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '인증 코드',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: _busy ? const _Spinner() : const Text('확인'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _phase = _Phase.email),
              child: const Text('이메일 다시 입력'),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}

class _DisabledOAuthButton extends StatelessWidget {
  const _DisabledOAuthButton({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: null, // linkIdentity 코드 자리만 — 네이티브 설정 후 활성화
      child: Text(label),
    );
  }
}
