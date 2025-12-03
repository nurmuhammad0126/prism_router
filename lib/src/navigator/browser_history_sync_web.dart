import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'history_constants.dart';

class BrowserHistorySync {
  const BrowserHistorySync();

  RouteRestorationPayload? readInitialPayload() {
    try {
      final uri = Uri.parse(web.window.location.href);
      final location =
          Uri(
            path: uri.path.isEmpty ? '/' : uri.path,
            query: uri.hasQuery ? uri.query : null,
            fragment: uri.hasFragment ? uri.fragment : null,
          ).toString();
      final state = web.window.history.state;
      String? stateKey;
      if (state is JSAny) {
        final dartValue = state.dartify();
        if (dartValue is Map && dartValue[kElixirHistoryStateKey] is String) {
          stateKey = dartValue[kElixirHistoryStateKey] as String;
        }
      }
      final snapshot = stateKey != null ? snapshotFor(stateKey) : null;
      return RouteRestorationPayload(
        location: location,
        stateKey: stateKey,
        snapshot: snapshot,
      );
    } on Object {
      return null;
    }
  }

  void persistSnapshot(String key, String data) {
    try {
      web.window.sessionStorage.setItem(_snapshotStorageKey(key), data);
    } on Object {
      // ignore storage exceptions
    }
  }

  String? snapshotFor(String key) {
    try {
      return web.window.sessionStorage.getItem(_snapshotStorageKey(key));
    } on Object {
      return null;
    }
  }

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

  String _snapshotStorageKey(String key) => 'elixir_snapshot:$key';
}
