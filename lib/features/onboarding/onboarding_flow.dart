import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/events.dart';
import '../../core/models/animal.dart';
import '../../data/providers.dart';
import 'onboarding_data.dart';
import 'steps/animal_intro_screen.dart';
import 'steps/birth_input_step.dart';
import 'steps/confirm_step.dart';
import 'steps/reveal_step.dart';

enum _Step { welcome, input, confirm, reveal, intro }

/// 온보딩: 웰컴 → 입력 → 확인(D1 안내) → 배정(calc-saju) → 연출 → 소개.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key, required this.onComplete});

  /// 소개 화면에서 "시작하기" → 홈으로.
  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  _Step _step = _Step.welcome;
  BirthInputData? _input;
  Animal? _animal;
  bool _assigning = false;
  String? _error;

  Future<void> _assign() async {
    setState(() {
      _assigning = true;
      _error = null;
    });
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final result = await repo.assign(
        birthDate: _input!.birthDate,
        calendarType: _input!.calendarType,
        isLeapMonth: _input!.isLeapMonth,
        birthTime: _input!.birthTime,
        gender: _input!.gender,
      );
      final catalog = await ref.read(animalCatalogProvider.future);
      final animal = catalog[result.animalId];
      if (animal == null) throw Exception('알 수 없는 동물: ${result.animalId}');

      await AnalyticsService.instance.capture(
        AnalyticsEvents.onboardingComplete,
        properties: {'animal_id': animal.id},
      );
      // 프로필 reload는 "시작하기"(onComplete) 시점에 — 연출/소개 중 라우터가
      // 홈으로 채가지 않도록.

      if (!mounted) return;
      setState(() {
        _animal = animal;
        _step = _Step.reveal;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildStep()),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.welcome:
        return _Welcome(onStart: () => setState(() => _step = _Step.input));
      case _Step.input:
        return BirthInputStep(
          onSubmit: (data) => setState(() {
            _input = data;
            _step = _Step.confirm;
          }),
        );
      case _Step.confirm:
        return Column(
          children: [
            Expanded(
              child: ConfirmStep(
                input: _input!,
                busy: _assigning,
                onConfirm: _assign,
                onEdit: () => setState(() => _step = _Step.input),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        );
      case _Step.reveal:
        return RevealStep(
          animal: _animal!,
          onDone: () => setState(() => _step = _Step.intro),
        );
      case _Step.intro:
        return AnimalIntroScreen(animal: _animal!, onStart: widget.onComplete);
    }
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text('🐾', style: text.displayLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('내 동물은 누구일까?',
              style: text.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            '사주가 정해준 단 하나의 동물이\n매일 너에게 운세를 건네줄 거야.',
            style: text.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: onStart,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('내 동물 찾기'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
