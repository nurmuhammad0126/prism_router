import 'package:elixir/elixir.dart';
import 'package:flutter/material.dart';

import 'routes_ultra_simple.dart';

mixin RouteStateMixin<T extends StatefulWidget> on State<T> {
  late ElixirNavigationState initialPages;

  late ElixirGuard guards;

  late List<ElixirPage> appPages;

  @override
  void initState() {
    super.initState();
    initialPages = [const HomePage()];

    guards = [
      (context, state) => state.length > 1 ? state : [const HomePage()],
    ];
    // Use pages list instead of definitions - much simpler!
    appPages = pages;
  }
}
