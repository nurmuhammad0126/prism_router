const String kElixirHistoryStateKey = 'elixirEntryId';

/// Carries the browser-provided location and state key used to restore the
/// navigation stack after a refresh.
class RouteRestorationPayload {
  const RouteRestorationPayload({
    required this.location,
    this.stateKey,
    this.snapshot,
  });

  final String location;
  final String? stateKey;
  final String? snapshot;
}
