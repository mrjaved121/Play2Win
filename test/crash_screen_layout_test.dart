import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:premium_slots/core/config/api_config.dart';
import 'package:premium_slots/core/di/service_locator.dart';
import 'package:premium_slots/core/services/storage_service.dart';
import 'package:premium_slots/features/crash/presentation/screens/crash_screen.dart';

/// Regression coverage for a real bug: the bet-controls row used
/// `crossAxisAlignment: stretch` without a bounded height, which passed an
/// infinite-height constraint down and crashed the whole screen on some
/// aspect ratios (reported as "just shows a wide/blank screen").
///
/// MUST be run with `--dart-define=API_BASE_URL=<something non-empty>` —
/// without it, [ApiConfig.isConfigured] is false and [CrashScreen] just
/// renders its "server not configured" placeholder, which would pass
/// trivially without exercising the real layout at all.

class _FakeStorageService implements StorageService {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  Future<void> init() async {}

  @override
  T? get<T>(String key, {String box = StorageService.defaultBox}) => _values[key] as T?;

  @override
  Future<void> put<T>(String key, T value, {String box = StorageService.defaultBox}) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key, {String box = StorageService.defaultBox}) async {
    _values.remove(key);
  }

  @override
  Future<void> clear({String box = StorageService.defaultBox}) async => _values.clear();

  @override
  bool containsKey(String key, {String box = StorageService.defaultBox}) => _values.containsKey(key);
}

void main() {
  setUpAll(() {
    if (!ApiConfig.isConfigured) {
      fail(
        'ApiConfig.isConfigured is false — re-run with '
        '--dart-define=API_BASE_URL=http://localhost:3000 (or any non-empty '
        "value) or this test silently checks nothing, see this file's doc comment.",
      );
    }
  });

  setUp(() {
    getIt.registerSingleton<StorageService>(_FakeStorageService());
  });

  tearDown(() {
    getIt.reset();
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CrashScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Crash screen on a typical phone size (390x844)', (WidgetTester tester) async {
    await pumpAt(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Crash screen on a wide/short window (800x600, default test size)', (WidgetTester tester) async {
    await pumpAt(tester, const Size(800, 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Crash screen on a short phone (360x640)', (WidgetTester tester) async {
    await pumpAt(tester, const Size(360, 640));
    expect(tester.takeException(), isNull);
  });
}
