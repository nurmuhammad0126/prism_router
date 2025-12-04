import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';

import '../routes/route_state_mixin.dart';

/// {@template app}
/// App widget.
/// {@endtemplate}
class App extends StatefulWidget {
  /// {@macro app}
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with RouteStateMixin {
  final GlobalKey<State<StatefulWidget>> _preserveKey =
      GlobalKey<State<StatefulWidget>>();

  late final RouterConfig<Object> _routerConfig;

  @override
  void initState() {
    super.initState();
    _routerConfig = PrismRouter.router(
      pages: appPages, // Use pages instead of routes - much simpler!
      initialStack: initialPages,
      guards: guards,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    key: _preserveKey,
    title: 'Declarative Navigation',
    debugShowCheckedModeBanner: false,
    routerConfig: _routerConfig,
  );
}
