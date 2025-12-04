import 'package:flutter/widgets.dart';

import 'prism_page.dart';

/// Type definition for the navigation state.
typedef PrismNavigationState = List<PrismPage>;

/// Type definition for the guard.
typedef PrismGuard =
    List<
      PrismNavigationState Function(
        BuildContext context,
        PrismNavigationState state,
      )
    >;

/// Converts a location/state pair (usually provided by the browser) back into
/// a navigation stack so the app can restore its pages after refresh.
typedef PrismRouteDecoder =
    PrismNavigationState? Function(String location, String? stateKey);

/// Definition for a restorable route.
class PrismRouteDefinition {
  const PrismRouteDefinition({required this.name, required this.builder});

  /// Unique route name. Usually matches [PrismPage.name].
  final String name;

  /// Builds a page when restoring navigation state. Receives the arguments map
  /// that was provided when the page was first pushed.
  final PrismPage Function(Map<String, Object?> arguments) builder;
}
