import 'history_constants.dart';

/// Stub implementation used for non-web platforms.
class BrowserHistorySync {
  const BrowserHistorySync();

  RouteRestorationPayload? readInitialPayload() => null;

  void persistSnapshot(String key, String data) {}

  String? snapshotFor(String key) => null;

  void initialize({required String stateKey, required String location}) {}

  void update({required String location, required String stateKey}) {}

  void dispose() {}
}
