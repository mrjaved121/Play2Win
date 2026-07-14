import 'package:hive_flutter/hive_flutter.dart';

/// Local persistence abstraction backed by Hive.
///
/// Deliberately stores plain JSON-ish values (`String`, `num`, `bool`,
/// `Map<String, dynamic>`) rather than registered `HiveObject`/TypeAdapter
/// classes: feature models serialize via Freezed's generated `toJson()` /
/// `fromJson()` and this service just persists the resulting map. That
/// keeps Hive usage generator-free (see the `hive_generator` /
/// `riverpod_generator` version conflict noted in the pubspec) while
/// still giving every feature typed, code-generated models.
abstract class StorageService {
  Future<void> init();

  T? get<T>(String key, {String box = StorageService.defaultBox});
  Future<void> put<T>(String key, T value, {String box = StorageService.defaultBox});
  Future<void> remove(String key, {String box = StorageService.defaultBox});
  Future<void> clear({String box = StorageService.defaultBox});
  bool containsKey(String key, {String box = StorageService.defaultBox});

  static const String defaultBox = 'app_storage';
}

class HiveStorageService implements StorageService {
  final Map<String, Box<dynamic>> _openBoxes = <String, Box<dynamic>>{};
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _openBoxes[StorageService.defaultBox] =
        await Hive.openBox<dynamic>(StorageService.defaultBox);
    _initialized = true;
  }

  Box<dynamic> _boxFor(String name) {
    final Box<dynamic>? box = _openBoxes[name];
    if (box == null) {
      throw StateError(
        'Hive box "$name" is not open. Call StorageService.init() '
        '(and openBox() for feature-specific boxes) before use.',
      );
    }
    return box;
  }

  /// Opens (and caches) an additional named box, for features that want
  /// isolated storage (e.g. `wallet`, `missions`) instead of the shared
  /// default box.
  Future<void> openBox(String name) async {
    if (_openBoxes.containsKey(name)) return;
    _openBoxes[name] = await Hive.openBox<dynamic>(name);
  }

  @override
  T? get<T>(String key, {String box = StorageService.defaultBox}) {
    return _boxFor(box).get(key) as T?;
  }

  @override
  Future<void> put<T>(
    String key,
    T value, {
    String box = StorageService.defaultBox,
  }) {
    return _boxFor(box).put(key, value);
  }

  @override
  Future<void> remove(String key, {String box = StorageService.defaultBox}) {
    return _boxFor(box).delete(key);
  }

  @override
  Future<void> clear({String box = StorageService.defaultBox}) {
    return _boxFor(box).clear();
  }

  @override
  bool containsKey(String key, {String box = StorageService.defaultBox}) {
    return _boxFor(box).containsKey(key);
  }
}
