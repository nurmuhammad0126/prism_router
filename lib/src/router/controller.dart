import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../navigator/elixir_page.dart';
import '../navigator/observer.dart';
import '../navigator/types.dart';

class ElixirController extends ChangeNotifier {
  ElixirController({
    required List<ElixirPage> initialPages,
    required ElixirGuard guards,
  }) : _guards = guards,
       _state = UnmodifiableListView(initialPages),
       _initialPages = UnmodifiableListView(initialPages) {
    _observer = ElixirObserver$NavigatorImpl(_state);
  }

  final ElixirGuard _guards;
  final UnmodifiableListView<ElixirPage> _initialPages;
  late UnmodifiableListView<ElixirPage> _state;
  late final ElixirObserver$NavigatorImpl _observer;
  BuildContext? _guardContext;

  UnmodifiableListView<ElixirPage> get state => _state;

  ElixirStateObserver get observer => _observer;

  /// Returns true if we're at the initial state (same as initial pages).
  bool get isAtInitialState {
    if (_state.length != _initialPages.length) return false;
    for (var i = 0; i < _state.length; i++) {
      if (_state[i].name != _initialPages[i].name) return false;
    }
    return true;
  }

  // ignore: use_setters_to_change_properties
  void attach(BuildContext context) {
    _guardContext = context;
  }

  /// Pops the current page from the navigation stack.
  ///
  /// Returns `true` if a page was popped, `false` if the stack has only one page.
  bool pop() {
    if (_state.length < 2) return false;
    change((pages) => pages..removeLast());
    return true;
  }

  /// Pushes a new page onto the navigation stack.
  ///
  /// Prevents pushing the same page if it's already at the top of the stack.
  void push(ElixirPage page) {
    if (_state.isNotEmpty && _state.last.name == page.name) {
      // Don't push the same page twice
      return;
    }
    change((pages) => pages..add(page));
  }

  /// Replaces the top page with a new page (equivalent to pushReplacement).
  ///
  /// If the stack is empty, pushes the page instead.
  void pushReplacement(ElixirPage page) {
    if (_state.isEmpty) {
      push(page);
      return;
    }
    // Don't replace if it's the same page
    if (_state.last.name == page.name) {
      return;
    }
    change((pages) => [...pages..removeLast(), page]);
  }

  /// Pushes a new page and removes all previous pages until the predicate is true.
  ///
  /// Equivalent to `pushAndRemoveUntil` in Flutter Navigator.
  void pushAndRemoveUntil(
    ElixirPage page,
    bool Function(ElixirPage) predicate,
  ) {
    final newStack = <ElixirPage>[];
    // Keep pages until predicate is true
    for (final existingPage in _state.reversed) {
      if (predicate(existingPage)) {
        newStack.insert(0, existingPage);
        break;
      }
    }
    // Add the new page
    newStack.add(page);
    resetTo(newStack);
  }

  /// Resets the stack to the given pages (equivalent to pushAndRemoveUntil with always false).
  ///
  /// Removes all previous pages and sets the stack to the given pages.
  void pushAndRemoveAll(ElixirPage page) {
    resetTo([page]);
  }

  /// Resets the stack to the given pages.
  ///
  /// This is a lower-level method. Prefer [pushAndRemoveAll] or [pushAndRemoveUntil] for common use cases.
  void resetTo(List<ElixirPage> pages) {
    if (pages.isEmpty) return;
    _setState(_applyGuards(List<ElixirPage>.from(pages)));
  }

  /// Resets the stack to the given pages (alias for resetTo).
  @Deprecated('Use resetTo instead')
  void reset(List<ElixirPage> pages) => resetTo(pages);

  /// Replaces the top page with a new page (alias for pushReplacement).
  @Deprecated('Use pushReplacement instead')
  void replaceTop(ElixirPage page) => pushReplacement(page);

  void change(List<ElixirPage> Function(List<ElixirPage> current) transform) {
    final next = transform(_state.toList());
    if (next.isEmpty) return;
    final guarded = _applyGuards(List<ElixirPage>.from(next));
    _setState(guarded);
  }

  void setFromRouter(List<ElixirPage> pages) =>
      _setState(List<ElixirPage>.from(pages), force: true);

  List<ElixirPage> _applyGuards(List<ElixirPage> next) {
    if (next.isEmpty) return next;
    final ctx = _guardContext;
    if (ctx == null || _guards.isEmpty) return next;
    return _guards.fold<List<ElixirPage>>(next, (state, guard) {
      final guarded = guard(ctx, List<ElixirPage>.from(state));
      return guarded.isEmpty ? state : guarded;
    });
  }

  void _setState(List<ElixirPage> next, {bool force = false}) {
    final immutable = UnmodifiableListView<ElixirPage>(next);
    if (!force && listEquals(immutable, _state)) return;
    _state = immutable;
    _observer.changeState((_) => _state);
    notifyListeners();
  }
}
