import 'package:flutter/material.dart';
import 'package:prism_router/prism_router.dart';

/// {@template custom_material_route}
/// CustomMaterialRoute widget.
/// {@endtemplate}
class CustomMaterialRoute extends PageRoute<void> {
  /// {@macro custom_material_route}
  CustomMaterialRoute({required PrismPage page}) : super(settings: page);

  /// {@macro custom_material_route}
  PrismPage get page => settings as PrismPage;

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
