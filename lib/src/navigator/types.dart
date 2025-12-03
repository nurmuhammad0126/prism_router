import 'package:flutter/widgets.dart';

import 'elixir_page.dart';

/// Type definition for the navigation state.
typedef ElixirNavigationState = List<ElixirPage>;

/// Type definition for the guard.
typedef ElixirGuard =
    List<
      ElixirNavigationState Function(
        BuildContext context,
        ElixirNavigationState state,
      )
    >;

/// Converts a location/state pair (usually provided by the browser) back into
/// a navigation stack so the app can restore its pages after refresh.
typedef ElixirRouteDecoder =
    ElixirNavigationState? Function(String location, String? stateKey);

/// Definition for a restorable route.
class ElixirRouteDefinition {
  const ElixirRouteDefinition({required this.name, required this.builder});

  /// Unique route name. Usually matches [ElixirPage.name].
  final String name;

  /// Builds a page when restoring navigation state. Receives the arguments map
  /// that was provided when the page was first pushed.
  final ElixirPage Function(Map<String, Object?> arguments) builder;
}
