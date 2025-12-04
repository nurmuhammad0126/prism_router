import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';

import 'routes_ultra_simple.dart';

mixin RouteStateMixin<T extends StatefulWidget> on State<T> {
  late PrismNavigationState initialPages;

  late PrismGuard guards;

  late List<PrismPage> appPages;

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
