import 'dart:collection';

import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/widgets.dart';

import '../navigator/observer.dart';
import '../navigator/prism_page.dart';
import '../navigator/types.dart';
import 'path_codec.dart';
import 'web_history_stub.dart' if (dart.library.html) 'web_history_web.dart';

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
  UnmodifiableListView<PrismPage> _initialPages;
  late UnmodifiableListView<PrismPage> _state;
  late final PrismObserver$NavigatorImpl _observer;
  BuildContext? _guardContext;
  bool _isClearingHistory = false;

  UnmodifiableListView<PrismPage> get state => _state;

  PrismStateObserver get observer => _observer;

  /// Returns true if we're at the initial state (same as initial pages).
  /// Compares both name and key to ensure exact match.
  bool get isAtInitialState {
    if (_state.length != _initialPages.length) return false;
    for (var i = 0; i < _state.length; i++) {
      final currentPage = _state[i];
      final initialPage = _initialPages[i];
      // Compare both name and key for exact match
      if (currentPage.name != initialPage.name ||
          currentPage.key != initialPage.key) {
        return false;
      }
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
  /// This also updates the initial state to prevent back navigation.
  /// On web, this clears all browser history and sets only the new page.
  void pushAndRemoveAll(PrismPage page) {
    final newStack = [page];
    // Update initial pages to the new stack to prevent back navigation
    // This ensures isAtInitialState returns true, preventing back button navigation
    _initialPages = UnmodifiableListView(newStack);

    // On web, clear all browser history using location.replace()
    // This is the ONLY way to truly clear all browser history
    if (kIsWeb) {
      final location = encodeLocation(newStack);
      final normalizedLocation =
          location.startsWith('/') ? location : '/$location';
      
      // Mark that we're clearing history to prevent router from updating URL
      _isClearingHistory = true;
      
      // Clear all browser history - this replaces entire URL and clears ALL history
      // After this, the page will reload and router will restore state from URL
      clearAndSetBrowserHistory(normalizedLocation);
      
      // Don't call setStack here - location.replace() causes reload,
      // and router will restore state from URL after reload
      // The flag will be reset after reload
      return;
    }

    // For non-web platforms, set stack normally
    setStack(newStack);
  }
  
  /// Returns true if history is being cleared (prevents router from updating URL)
  bool get isClearingHistory => _isClearingHistory;
  
  /// Reset the history clearing flag (called after reload)
  void resetHistoryClearingFlag() {
    _isClearingHistory = false;
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

  void setFromRouter(List<PrismPage> pages) {
    // When restoring from URL, preserve arguments from current state
    // if the new pages don't have them (URL doesn't contain arguments)
    final pagesWithArgs = <PrismPage>[];
    for (var i = 0; i < pages.length; i++) {
      final newPage = pages[i];
      // If current state has a page at this position with the same name,
      // and new page has empty arguments, preserve current page's arguments
      if (i < _state.length &&
          _state[i].name == newPage.name &&
          newPage.arguments.isEmpty &&
          _state[i].arguments.isNotEmpty) {
        // Keep the current page with its arguments instead of replacing with empty one
        pagesWithArgs.add(_state[i]);
      } else {
        // Use the new page (either different name or has arguments)
        pagesWithArgs.add(newPage);
      }
    }
    _setState(pagesWithArgs, force: true);
  }

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
    // Compare by name and arguments to avoid unnecessary updates
    if (!force) {
      // Check if pages are actually different
      if (immutable.length == _state.length) {
        var isDifferent = false;
        for (var i = 0; i < immutable.length; i++) {
          final current = _state[i];
          final nextPage = immutable[i];
          // Compare by name, key, and arguments
          if (current.name != nextPage.name ||
              current.key != nextPage.key ||
              !_mapsEqual(current.arguments, nextPage.arguments)) {
            isDifferent = true;
            break;
          }
        }
        if (!isDifferent) return;
      } else {
        // Different length, definitely different
        if (listEquals(immutable, _state)) return;
      }
    }
    _state = immutable;
    _observer.changeState((_) => _state);
    notifyListeners();
  }

  // Helper to compare maps
  bool _mapsEqual(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
