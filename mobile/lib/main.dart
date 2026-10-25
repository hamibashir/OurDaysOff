import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/storage/offline_cache_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final offlineCache = OfflineCacheService();
  await offlineCache.init();

  runApp(
    ProviderScope(
      overrides: [
        offlineCacheServiceProvider.overrideWithValue(offlineCache),
      ],
      child: const OurDaysOffApp(),
    ),
  );
}

class OurDaysOffApp extends ConsumerWidget {
  const OurDaysOffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Our Days Off',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
