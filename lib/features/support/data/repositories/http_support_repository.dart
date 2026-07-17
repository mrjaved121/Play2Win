import '../../domain/entities/support_entry.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_api_client.dart';

class HttpSupportRepository implements SupportRepository {
  HttpSupportRepository(this._client);

  final SupportApiClient _client;

  @override
  Future<List<SupportEntry>> fetchEntries() async {
    final List<Map<String, dynamic>> rows = await _client.fetchEntries();
    return rows.map(SupportEntry.fromJson).toList();
  }
}
