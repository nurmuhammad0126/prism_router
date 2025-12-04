import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../navigator/observer.dart';
import '../navigator/prism_page.dart';
import '../navigator/types.dart';

class PrismController extends ChangeNotifier {
  PrismController({
    required List<PrismPage> initialPages,
    required PrismGuard guards,
  }) : _guards = guards,
       _state = UnmodifiableListView(initialPages),
       _initialPages = UnmodifiableListView(initialPages) {
    _observer = PrismObserver$NavigatorImpl(_state);
  }

  final PrismGuard _guards;
  final UnmodifiableListView<PrismPage> _initialPages;
  late UnmodifiableListView<PrismPage> _state;
  late final PrismObserver$NavigatorImpl _observer;
  BuildContext? _guardContext;

  UnmodifiableListView<PrismPage> get state => _state;

  PrismStateObserver get observer => _observer;

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
    transformStack((pages) => pages..removeLast());
    return true;
  }

  /// Pushes a new page onto the navigation stack.
  ///
  /// Prevents pushing the same page if it's already at the top of the stack.
  void push(PrismPage page) {
    if (_state.isNotEmpty && _state.last.name == page.name) {
      // Don't push the same page twice
      return;
    }
    transformStack((pages) => pages..add(page));
  }

  /// Replaces the top page with a new page.
  ///
  /// If the stack is empty, pushes the page instead.
  void pushReplacement(PrismPage page) {
    if (_state.isEmpty) {
      push(page);
      return;
    }
    // Don't replace if it's the same page
    if (_state.last.name == page.name) {
      return;
    }
    transformStack((pages) => [...pages..removeLast(), page]);
  }

  /// Pushes a new page and removes all previous pages until the predicate is true.
  ///
  /// Equivalent to `pushAndRemoveUntil` in Flutter Navigator.
  void pushAndRemoveUntil(PrismPage page, bool Function(PrismPage) predicate) {
    final newStack = <PrismPage>[];
    // Keep pages until predicate is true
    for (final existingPage in _state.reversed) {
      if (predicate(existingPage)) {
        newStack.insert(0, existingPage);
        break;
      }
    }
    // Add the new page
    newStack.add(page);
    setStack(newStack);
  }

  /// Pushes a new page and removes all previous pages.
  ///
  /// Equivalent to `pushAndRemoveUntil` with always false predicate.
  void pushAndRemoveAll(PrismPage page) {
    setStack([page]);
  }

  /// Sets the navigation stack to the given pages.
  ///
  /// This replaces the entire navigation stack with the provided pages.
  /// Prefer [pushAndRemoveAll] or [pushAndRemoveUntil] for common use cases.
  void setStack(List<PrismPage> pages) {
    if (pages.isEmpty) return;
    _setState(_applyGuards(List<PrismPage>.from(pages)));
  }

  /// Applies a custom transformation to the navigation stack.
  ///
  /// Use this for advanced navigation scenarios where you need fine-grained control.
  void transformStack(
    List<PrismPage> Function(List<PrismPage> current) transform,
  ) {
    final next = transform(_state.toList());
    if (next.isEmpty) return;
    final guarded = _applyGuards(List<PrismPage>.from(next));
    _setState(guarded);
  }

  void setFromRouter(List<PrismPage> pages) =>
      _setState(List<PrismPage>.from(pages), force: true);

  List<PrismPage> _applyGuards(List<PrismPage> next) {
    if (next.isEmpty) return next;
    final ctx = _guardContext;
    if (ctx == null || _guards.isEmpty) return next;
    return _guards.fold<List<PrismPage>>(next, (state, guard) {
      final guarded = guard(ctx, List<PrismPage>.from(state));
      return guarded.isEmpty ? state : guarded;
    });
  }

  void _setState(List<PrismPage> next, {bool force = false}) {
    final immutable = UnmodifiableListView<PrismPage>(next);
    if (!force && listEquals(immutable, _state)) return;
    _state = immutable;
    _observer.changeState((_) => _state);
    notifyListeners();
  }
}
