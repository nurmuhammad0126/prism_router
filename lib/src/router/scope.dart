import 'package:flutter/widgets.dart';

import 'controller.dart';

class ElixirScope extends StatefulWidget {
  const ElixirScope({required this.controller, required this.child, super.key});

  final ElixirController controller;
  final Widget child;

  static ElixirController of(BuildContext context, {bool listen = true}) {
    final scope =
        listen
            ? context
                .dependOnInheritedWidgetOfExactType<_InheritedElixirScope>()
            : context.getInheritedWidgetOfExactType<_InheritedElixirScope>();
    assert(scope != null, 'No ElixirScope found in context.');
    return scope!.controller;
  }

  @override
  State<ElixirScope> createState() => _ElixirScopeState();
}

class _ElixirScopeState extends State<ElixirScope> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller.attach(context);
  }

  @override
  Widget build(BuildContext context) =>
      _InheritedElixirScope(controller: widget.controller, child: widget.child);
}

class _InheritedElixirScope extends InheritedWidget {
  const _InheritedElixirScope({required this.controller, required super.child});

  final ElixirController controller;

  @override
  bool updateShouldNotify(covariant _InheritedElixirScope oldWidget) =>
      !identical(controller, oldWidget.controller);
}
