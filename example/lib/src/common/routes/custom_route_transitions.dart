import 'package:elixir/elixir.dart';
import 'package:flutter/material.dart';

/// {@template custom_material_route}
/// CustomMaterialRoute widget.
/// {@endtemplate}
class CustomMaterialRoute extends PageRoute<void> {
  /// {@macro custom_material_route}
  CustomMaterialRoute({required ElixirPage page}) : super(settings: page);

  /// {@macro custom_material_route}
  ElixirPage get page => settings as ElixirPage;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => page.child;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => const ZoomPageTransitionsBuilder().buildTransitions(
    this,
    context,
    animation,
    secondaryAnimation,
    child,
  );
}
