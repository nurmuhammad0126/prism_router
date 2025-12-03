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
