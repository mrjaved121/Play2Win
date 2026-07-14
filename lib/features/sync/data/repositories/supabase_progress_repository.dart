import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/progress_repository.dart';

/// Backed by a `player_progress` table: `user_id uuid primary key`,
/// `data jsonb`, `updated_at timestamptz` — see the SQL migration in the
/// sync feature's setup notes. Row Level Security scopes every row to
/// `auth.uid()`, so this repository never needs to filter by caller.
class SupabaseProgressRepository implements ProgressRepository {
  SupabaseProgressRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'player_progress';

  @override
  Future<Map<String, dynamic>?> fetch(String userId) async {
    final Map<String, dynamic>? row =
        await _client.from(_table).select('data').eq('user_id', userId).maybeSingle();
    if (row == null) return null;
    return (row['data'] as Map<dynamic, dynamic>).cast<String, dynamic>();
  }

  @override
  Future<void> push(String userId, Map<String, dynamic> snapshot) async {
    await _client.from(_table).upsert(<String, dynamic>{
      'user_id': userId,
      'data': snapshot,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
