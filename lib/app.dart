import 'package:flutter/material.dart';

import 'features/debug/debug_home_screen.dart';

class FortuneApp extends StatelessWidget {
  const FortuneApp({super.key, required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '운세 동물 컴패니언',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8C9A0)),
      ),
      home: DebugHomeScreen(supabaseReady: supabaseReady),
    );
  }
}
