import 'package:flutter/material.dart';

import '../onboarding_data.dart';

/// 생년월일·양음력·시간(선택)·성별(선택) 입력.
class BirthInputStep extends StatefulWidget {
  const BirthInputStep({super.key, required this.onSubmit});

  final void Function(BirthInputData) onSubmit;

  @override
  State<BirthInputStep> createState() => _BirthInputStepState();
}

class _BirthInputStepState extends State<BirthInputStep> {
  DateTime? _date;
  String _calendarType = 'solar';
  bool _isLeapMonth = false;
  TimeOfDay? _time;
  bool _skipTime = true; // 기본 = 시간 모름(건너뛰기)
  String? _gender;

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: '생년월일 선택',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final d = _date!;
    widget.onSubmit(BirthInputData(
      birthDate: '${d.year}-${_two(d.month)}-${_two(d.day)}',
      calendarType: _calendarType,
      isLeapMonth: _calendarType == 'lunar' && _isLeapMonth,
      birthTime: _skipTime || _time == null
          ? null
          : '${_two(_time!.hour)}:${_two(_time!.minute)}',
      gender: _gender,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _date != null;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Text('너의 생년월일을 알려줘', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text('사주로 너의 동물을 찾아줄게', style: text.bodyMedium),
          const SizedBox(height: 24),

          // 양/음력
          Text('달력', style: text.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'solar', label: Text('양력')),
              ButtonSegment(value: 'lunar', label: Text('음력')),
            ],
            selected: {_calendarType},
            onSelectionChanged: (s) => setState(() {
              _calendarType = s.first;
              if (_calendarType == 'solar') _isLeapMonth = false;
            }),
          ),
          if (_calendarType == 'lunar')
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _isLeapMonth,
              onChanged: (v) => setState(() => _isLeapMonth = v ?? false),
              title: const Text('윤달이에요'),
            ),
          const SizedBox(height: 16),

          // 날짜
          Text('생년월일', style: text.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(_date == null
                ? '날짜 선택'
                : '${_date!.year}-${_two(_date!.month)}-${_two(_date!.day)}'),
          ),
          const SizedBox(height: 16),

          // 시간 (선택)
          Row(
            children: [
              Expanded(child: Text('태어난 시간 (선택)', style: text.titleMedium)),
              TextButton(
                onPressed: () => setState(() => _skipTime = !_skipTime),
                child: Text(_skipTime ? '입력하기' : '모르면 건너뛰기'),
              ),
            ],
          ),
          if (!_skipTime)
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time),
              label: Text(_time == null
                  ? '시간 선택'
                  : '${_two(_time!.hour)}:${_two(_time!.minute)}'),
            )
          else
            Text('시간은 나중에 상세 운세에 쓰여요', style: text.bodySmall),
          const SizedBox(height: 16),

          // 성별 (선택)
          Text('성별 (선택)', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final g in const [
                ('female', '여성'),
                ('male', '남성'),
              ])
                ChoiceChip(
                  label: Text(g.$2),
                  selected: _gender == g.$1,
                  onSelected: (sel) =>
                      setState(() => _gender = sel ? g.$1 : null),
                ),
            ],
          ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('다음'),
            ),
          ),
        ],
      ),
    );
  }
}
