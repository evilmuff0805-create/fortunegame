import 'package:flutter/material.dart';

import '../onboarding_data.dart';

/// 배정 직전 확인 — 오입력으로 동물이 영구 오배정되는 것을 막는 안전장치(D1).
/// "한 번 정해지면 못 바꾼다"를 분명히 알리되, 협박이 아닌 안내 톤(D5 위반 아님).
class ConfirmStep extends StatelessWidget {
  const ConfirmStep({
    super.key,
    required this.input,
    required this.onConfirm,
    required this.onEdit,
    this.busy = false,
  });

  final BirthInputData input;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.auto_awesome, size: 48, color: scheme.primary),
          const SizedBox(height: 16),
          Text('입력한 정보가 맞을까?',
              style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _Row(label: '생년월일', value: input.birthDate),
                  const Divider(height: 20),
                  _Row(
                    label: '달력',
                    value: '${input.calendarLabel}'
                        '${input.isLeapMonth ? ' · 윤달' : ''}',
                  ),
                  if (input.birthTime != null) ...[
                    const Divider(height: 20),
                    _Row(label: '시간', value: input.birthTime!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, size: 20, color: scheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '너의 동물은 이 생년월일로 정해지고, 한 번 정해지면 바꿀 수 없어. '
                    '그래서 평생 함께할 단 하나의 친구야. 날짜를 한 번만 더 확인해줘!',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          FilledButton(
            onPressed: busy ? null : onConfirm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('맞아, 내 동물을 만날래'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy ? null : onEdit,
            child: const Text('다시 입력할래'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: text.bodyMedium),
        Text(value,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
