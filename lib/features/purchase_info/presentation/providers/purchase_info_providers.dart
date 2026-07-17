import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../data/datasources/purchase_info_api_client.dart';
import '../../domain/entities/purchase_info.dart';

final Provider<PurchaseInfoApiClient> purchaseInfoApiClientProvider = Provider<PurchaseInfoApiClient>(
  (Ref ref) => PurchaseInfoApiClient(),
);

class PurchaseInfoState {
  const PurchaseInfoState({this.info, this.loading = true});

  final PurchaseInfo? info;
  final bool loading;
}

/// Loads the admin-managed "How to Buy Credits" content once on first
/// watch. An unconfigured/unreachable backend just leaves [info] null —
/// the screen renders its own "not available" copy for that, same as any
/// other content-fetch failure.
class PurchaseInfoNotifier extends Notifier<PurchaseInfoState> {
  @override
  PurchaseInfoState build() {
    if (ApiConfig.isConfigured) {
      unawaited(_load());
    }
    return PurchaseInfoState(loading: ApiConfig.isConfigured);
  }

  Future<void> _load() async {
    final PurchaseInfo? info = await ref.read(purchaseInfoApiClientProvider).fetch();
    state = PurchaseInfoState(info: info, loading: false);
  }

  Future<void> refresh() async {
    state = PurchaseInfoState(info: state.info, loading: true);
    await _load();
  }
}

final NotifierProvider<PurchaseInfoNotifier, PurchaseInfoState> purchaseInfoProvider =
    NotifierProvider<PurchaseInfoNotifier, PurchaseInfoState>(PurchaseInfoNotifier.new);
