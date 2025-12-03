import 'dart:async';

import 'package:flutter/services.dart';

import 'history_constants.dart';

class BrowserHistorySync {
  const BrowserHistorySync();

  void initialize({required String stateKey, required String location}) =>
      _updateHistory(stateKey: stateKey, location: location, replace: true);

  void update({required String location, required String stateKey}) =>
      _updateHistory(stateKey: stateKey, location: location);

  void dispose() {}

  void _updateHistory({
    required String stateKey,
    required String location,
    bool replace = false,
  }) {
    final uri = Uri.parse(location);
    unawaited(
      SystemNavigator.routeInformationUpdated(
        uri: uri,
        state: _buildPayload(stateKey),
        replace: replace,
      ),
    );
  }

  Map<String, Object?> _buildPayload(String stateKey) => {
    kElixirHistoryStateKey: stateKey,
  };
}
