import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/animal.dart';
import '../../data/providers.dart';
import 'daily_repository.dart';
import 'envelope_tear.dart';
import 'fortune_card_screen.dart';

/// 개봉 플로우: 찢기(EnvelopeTear) → open-pack(서버 권위) → 운세 카드.
class DailyOpenScreen extends ConsumerStatefulWidget {
  const DailyOpenScreen({super.key, required this.animal, required this.leak});

  final Animal animal;
  final String leak;

  @override
  ConsumerState<DailyOpenScreen> createState() => _DailyOpenScreenState();
}

class _DailyOpenScreenState extends ConsumerState<DailyOpenScreen> {
  bool _opening = false;
  OpenResult? _result;
  String? _error;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final r = await ref.read(dailyRepositoryProvider).open();
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return FortuneCardScreen(
        animal: widget.animal,
        result: _result!,
        onClose: () => Navigator.of(context).pop(),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _opening
              ? const CircularProgressIndicator()
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('열다가 문제가 생겼어: $_error',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: () => setState(() => _error = null),
                              child: const Text('다시 시도')),
                        ],
                      ),
                    )
                  : EnvelopeTear(
                      leak: widget.leak,
                      deliverImage: widget.animal.deliverAsset,
                      onOpened: _open,
                    ),
        ),
      ),
    );
  }
}
