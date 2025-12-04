import 'package:flutter/material.dart';

import '../navigator/elixir_page.dart';
import '../router/controller.dart';
import '../router/scope.dart';

extension ElixirContextExtension on BuildContext {
  /// Gets the Elixir controller for navigation.
  ElixirController get elixir => ElixirScope.of(this, listen: false);

  /// Checks if a page can be popped from the navigation stack.
  bool get canPop => Navigator.canPop(this);

  /// Pops the current page from the navigation stack.
  void pop() => elixir.pop();

  /// Pushes a new page onto the navigation stack.
  ///
  /// Prevents pushing the same page if it's already at the top of the stack.
  void push(ElixirPage page) {
    final controller = elixir;
    if (controller.state.isNotEmpty &&
        controller.state.last.name == page.name) {
      // Don't push the same page twice - prevents errors
      return;
    }
    controller.push(page);
  }

  /// Replaces the top page with a new page (equivalent to pushReplacement).
  void pushReplacement(ElixirPage page) => elixir.pushReplacement(page);

  /// Pushes a new page and removes all previous pages until the predicate is true.
  void pushAndRemoveUntil(
    ElixirPage page,
    bool Function(ElixirPage) predicate,
  ) => elixir.pushAndRemoveUntil(page, predicate);

  /// Pushes a new page and removes all previous pages.
  void pushAndRemoveAll(ElixirPage page) => elixir.pushAndRemoveAll(page);

  /// Resets the navigation stack to the given pages.
  void resetTo(List<ElixirPage> pages) => elixir.resetTo(pages);

  /// Applies a custom transformation to the navigation stack.
  void change(List<ElixirPage> Function(List<ElixirPage> current) transform) =>
      elixir.change(transform);
}
