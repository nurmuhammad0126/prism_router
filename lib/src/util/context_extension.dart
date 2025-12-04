import 'package:flutter/material.dart';

import '../navigator/prism_page.dart';
import '../router/controller.dart';
import '../router/scope.dart';

extension PrismContextExtension on BuildContext {
  /// Gets the Prism controller for navigation.
  PrismController get prism => PrismScope.of(this, listen: false);

  /// Checks if a page can be popped from the navigation stack.
  bool get canPop => Navigator.canPop(this);

  /// Pops the current page from the navigation stack.
  void pop() => prism.pop();

  /// Pushes a new page onto the navigation stack.
  ///
  /// Prevents pushing the same page if it's already at the top of the stack.
  void push(PrismPage page) {
    final controller = prism;
    if (controller.state.isNotEmpty &&
        controller.state.last.name == page.name) {
      // Don't push the same page twice - prevents errors
      return;
    }
    controller.push(page);
  }

  /// Replaces the top page with a new page (equivalent to pushReplacement).
  void pushReplacement(PrismPage page) => prism.pushReplacement(page);

  /// Pushes a new page and removes all previous pages until the predicate is true.
  void pushAndRemoveUntil(PrismPage page, bool Function(PrismPage) predicate) =>
      prism.pushAndRemoveUntil(page, predicate);

  /// Pushes a new page and removes all previous pages.
  void pushAndRemoveAll(PrismPage page) => prism.pushAndRemoveAll(page);

  /// Resets the navigation stack to the given pages.
  void resetTo(List<PrismPage> pages) => prism.resetTo(pages);

  /// Applies a custom transformation to the navigation stack.
  void change(List<PrismPage> Function(List<PrismPage> current) transform) =>
      prism.change(transform);
}
