import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../navigator/elixir_page.dart';
import '../navigator/navigator.dart';
import '../navigator/types.dart';

extension ElixirContextExtension on BuildContext {
  ElixirState get elixir => Elixir.of(this);
}

extension ElixirControllerExtension on ValueNotifier<ElixirNavigationState> {
  void change(ElixirNavigationState Function(ElixirNavigationState pages) fn) {
    final prev = value.toList();
    var next = fn(prev);
    if (next.isEmpty || listEquals<ElixirPage>(next, value)) return;
    value = UnmodifiableListView<ElixirPage>(next);
  }
}
