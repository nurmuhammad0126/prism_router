import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../navigator/elixir_page.dart';
import '../navigator/types.dart';
import 'back_button_dispatcher.dart';
import 'controller.dart';
import 'path_codec.dart';
import 'route_information_parser.dart';
import 'router_delegate.dart';

class Elixir {
  const Elixir._();

  static RouterConfig<Object> router({
    required List<ElixirRouteDefinition> routes,
    required List<ElixirPage> initialStack,
    ElixirGuard guards = const [],
    List<NavigatorObserver> observers = const [],
    TransitionDelegate<Object> transitionDelegate =
        const DefaultTransitionDelegate<Object>(),
    String? restorationScopeId,
  }) {
    assert(initialStack.isNotEmpty, 'initialStack cannot be empty');
    final controller = ElixirController(
      initialPages: initialStack,
      guards: guards,
    );
    final routeMap = {for (final route in routes) route.name: route};
    final delegate = ElixirRouterDelegate(
      controller: controller,
      observers: observers,
      transitionDelegate: transitionDelegate,
      restorationScopeId: restorationScopeId,
    );
    final parser = ElixirRouteInformationParser(
      routeBuilders: routeMap,
      initialPages: initialStack,
    );
    // initialRouteInformation is used as fallback if browser URL is empty
    // Parser will parse actual browser URL if it exists
    final initialLocation = encodeLocation(initialStack);
    final initialRouteInformation =
        kIsWeb
            // On web, read the actual browser URL so refresh preserves stacks.
            ? RouteInformation(uri: Uri.base)
            : RouteInformation(uri: Uri.parse(initialLocation));
    final provider = PlatformRouteInformationProvider(
      initialRouteInformation: initialRouteInformation,
    );
    return RouterConfig<Object>(
      routerDelegate: delegate,
      routeInformationParser: parser,
      routeInformationProvider: provider,
      backButtonDispatcher: ElixirBackButtonDispatcher(controller),
    );
  }
}
