import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../data/datasources/purchase_info_api_client.dart';
import '../../domain/entities/purchase_info.dart';

final Provider<PurchaseInfoApiClient> purchaseInfoApiClientProvider = Provider<PurchaseInfoApiClient>(
  (Ref ref) => PurchaseInfoApiClient(),
);

class PurchaseInfoState {
  const PurchaseInfoState({this.guides = const <PurchaseGuideEntry>[], this.loading = true, this.errorMessage});

  final List<PurchaseGuideEntry> guides;
  final bool loading;
  final String? errorMessage;

  PurchaseInfoState copyWith({
    List<PurchaseGuideEntry>? guides,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PurchaseInfoState(
      guides: guides ?? this.guides,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Loads the admin-managed How to Buy entries once on first watch. An
/// unconfigured/unreachable backend degrades to an empty/error state, not
/// a broken screen — this is display-only content, not gameplay-critical.
class PurchaseInfoNotifier extends Notifier<PurchaseInfoState> {
  @override
  PurchaseInfoState build() {
    if (ApiConfig.isConfigured) {
      unawaited(_load());
    }
    return PurchaseInfoState(loading: ApiConfig.isConfigured);
  }

  Future<void> _load() async {
    try {
      final List<Map<String, dynamic>> raw = await ref.read(purchaseInfoApiClientProvider).fetchGuides();
      final List<PurchaseGuideEntry> guides = raw.map(PurchaseGuideEntry.fromJson).toList();
      state = state.copyWith(guides: guides, loading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(
        loading: false,
        errorMessage: error is PurchaseInfoApiException ? error.message : "Can't reach the server",
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    await _load();
  }
}

final NotifierProvider<PurchaseInfoNotifier, PurchaseInfoState> purchaseInfoProvider =
    NotifierProvider<PurchaseInfoNotifier, PurchaseInfoState>(PurchaseInfoNotifier.new);
