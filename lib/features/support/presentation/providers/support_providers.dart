import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../data/datasources/support_api_client.dart';
import '../../data/repositories/http_support_repository.dart';
import '../../domain/entities/support_entry.dart';
import '../../domain/repositories/support_repository.dart';

final Provider<SupportApiClient> supportApiClientProvider = Provider<SupportApiClient>(
  (Ref ref) => SupportApiClient(),
);

final Provider<SupportRepository> supportRepositoryProvider = Provider<SupportRepository>(
  (Ref ref) => HttpSupportRepository(ref.watch(supportApiClientProvider)),
);

class SupportUiState {
  const SupportUiState({this.entries = const <SupportEntry>[], this.loading = true, this.errorMessage});

  final List<SupportEntry> entries;
  final bool loading;
  final String? errorMessage;

  SupportUiState copyWith({
    List<SupportEntry>? entries,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SupportUiState(
      entries: entries ?? this.entries,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Loads the admin-managed Help & Support entries once on first watch. The
/// "this is a demo" framing is static copy in [HelpSupportScreen] itself —
/// this only drives the FAQ-style entries below it, so an unconfigured or
/// unreachable server degrades to an empty/error state, not a broken screen.
class SupportNotifier extends Notifier<SupportUiState> {
  @override
  SupportUiState build() {
    if (ApiConfig.isConfigured) {
      unawaited(_load());
    }
    return SupportUiState(loading: ApiConfig.isConfigured);
  }

  SupportRepository get _repo => ref.read(supportRepositoryProvider);

  Future<void> _load() async {
    try {
      final List<SupportEntry> entries = await _repo.fetchEntries();
      state = state.copyWith(entries: entries, loading: false);
    } catch (error) {
      state = state.copyWith(
        loading: false,
        errorMessage: error is SupportApiException ? error.message : "Can't reach the support server",
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    await _load();
  }
}

final NotifierProvider<SupportNotifier, SupportUiState> supportProvider =
    NotifierProvider<SupportNotifier, SupportUiState>(SupportNotifier.new);
