import '../entities/support_entry.dart';

/// Boundary for the Help & Support content managed from blackhole_admin.
abstract class SupportRepository {
  Future<List<SupportEntry>> fetchEntries();
}
