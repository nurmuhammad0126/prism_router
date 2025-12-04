import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../navigator/prism_page.dart';
import 'controller.dart';
import 'scope.dart';

class PrismRouterDelegate extends RouterDelegate<List<PrismPage>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<List<PrismPage>> {
  PrismRouterDelegate({
    required this.controller,
    required this.transitionDelegate,
    required this.observers,
    this.restorationScopeId,
  }) {
    controller.addListener(_handleControllerChanged);
  }

  final PrismController controller;
  final TransitionDelegate<Object> transitionDelegate;
  final List<NavigatorObserver> observers;
  final String? restorationScopeId;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  @override
  List<PrismPage> get currentConfiguration => controller.state;

  final NavigatorObserver _internalObserver = NavigatorObserver();

  void _handleControllerChanged() {
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) => PrismScope(
    controller: controller,
    child: Navigator(
      key: navigatorKey,
      pages: controller.state,
      transitionDelegate: transitionDelegate,
      observers: <NavigatorObserver>[_internalObserver, ...observers],
      restorationScopeId: restorationScopeId,
      // ignore: deprecated_member_use
      onPopPage: (route, result) {
        final didPop = route.didPop(result);
        if (didPop) controller.pop();
        return didPop;
      },
    ),
  );

  @override
  Future<void> setNewRoutePath(List<PrismPage> configuration) {
    controller.setFromRouter(configuration);
    return SynchronousFuture<void>(null);
  }

  @override
  Future<bool> popRoute() {
    // If we're at initial state, can't pop - back button should be disabled
    if (controller.isAtInitialState) {
      return SynchronousFuture<bool>(false);
    }
    return SynchronousFuture<bool>(controller.pop());
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChanged);
    super.dispose();
  }
}
