/// Stub implementation used for non-web platforms.
class BrowserHistorySync {
  const BrowserHistorySync();

  void initialize({required String stateKey, required String location}) {}

  void update({required String location, required String stateKey}) {}

  void dispose() {}
}
