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

  bool pop() {
    if (_state.length < 2) return false;
    change((pages) => pages..removeLast());
    return true;
  }

  void push(ElixirPage page) => change((pages) => pages..add(page));

  /// Replaces the top page with a new page (equivalent to pushReplacement).
  void replaceTop(ElixirPage page) {
    if (_state.isEmpty) {
      push(page);
      return;
    }
    change((pages) => [...pages..removeLast(), page]);
  }

  /// Resets the stack to the given pages (equivalent to pushAndRemoveUntil).
  void resetTo(List<ElixirPage> pages) {
    if (pages.isEmpty) return;
    _setState(_applyGuards(List<ElixirPage>.from(pages)));
  }

  void reset(List<ElixirPage> pages) =>
      _setState(_applyGuards(List<ElixirPage>.from(pages)));

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
