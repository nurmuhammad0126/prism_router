import 'package:elixir/elixir.dart';
import 'package:flutter/material.dart';

import 'routes.dart';

mixin RouteStateMixin<T extends StatefulWidget> on State<T> {
  late ElixirNavigationState initialPages;

  late ElixirGuard guards;

  late List<ElixirRouteDefinition> routes;

  @override
  void initState() {
    super.initState();
    initialPages = [const HomePage()];

    guards = [
      (context, state) => state.length > 1 ? state : [const HomePage()],
    ];
    routes = [
      ElixirRouteDefinition(name: 'home', builder: (_) => const HomePage()),
      ElixirRouteDefinition(
        name: 'settings',
        builder:
            (arguments) =>
                SettingsPage(data: arguments['data'] as String? ?? ''),
      ),
      ElixirRouteDefinition(
        name: 'profile',
        builder: (_) => const ProfilePage(),
      ),
      ElixirRouteDefinition(
        name: 'details',
        builder:
            (arguments) => DetailsPage(
              userId: arguments['userId'] as String? ?? '',
              note: arguments['note'] as String? ?? '',
            ),
      ),
    ];
  }
}
