import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:premium_slots/app.dart';
import 'package:premium_slots/core/di/service_locator.dart';
import 'package:premium_slots/core/services/storage_service.dart';
import 'package:premium_slots/features/onboarding/presentation/providers/onboarding_providers.dart';

/// In-memory [StorageService] fake so widget tests don't touch real Hive
/// boxes/disk I/O (which need platform channels `Hive.initFlutter()`
/// relies on and aren't available under `flutter test`).
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

/// Skips onboarding in tests so they land straight on Home, without
/// depending on [_FakeStorageService] already having the "seen
/// onboarding" flag set.
class _AlreadyOnboardedNotifier extends OnboardingCompleteNotifier {
  @override
  bool build() => true;
}

void main() {
  setUp(() {
    getIt.registerSingleton<StorageService>(_FakeStorageService());
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('App boots and renders the Lobby screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingCompleteProvider.overrideWith(_AlreadyOnboardedNotifier.new),
        ],
        child: const PremiumSlotsApp(),
      ),
    );
    // Splash shows briefly, then navigates to Home (the Lobby) — pump past
    // its delay.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();
    // Avoid pumpAndSettle: the promo carousel's auto-rotate timer and the
    // jackpot glow are looping animations that never "settle".
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('TOP GAMES'), findsOneWidget);
    expect(find.text('Slot Machine'), findsOneWidget);
  });
}
