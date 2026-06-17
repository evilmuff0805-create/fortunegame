import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseReady = await SupabaseBootstrap.init();
  await AnalyticsService.instance.init();
  await NotificationService.instance.init();

  final userId = supabaseReady ? SupabaseBootstrap.currentUserId : null;
  if (userId != null) {
    await AnalyticsService.instance.identify(userId);
  }

  runApp(ProviderScope(child: FortuneApp(supabaseReady: supabaseReady)));
}
