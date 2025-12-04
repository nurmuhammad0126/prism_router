import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'types.dart';

/// Prism state observer
abstract interface class PrismStateObserver
    implements ValueListenable<PrismNavigationState> {
  /// Max history length.
  static const int maxHistoryLength = 10000;

  /// History.
  List<PrismHistoryEntry> get history;

  /// Set history
  void setHistory(Iterable<PrismHistoryEntry> history);
}

@immutable
final class PrismHistoryEntry implements Comparable<PrismHistoryEntry> {
  PrismHistoryEntry({required this.state, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// Navigation state
  final PrismNavigationState state;

  /// Timestamp of the entry
  final DateTime timestamp;

  @override
  int compareTo(covariant PrismHistoryEntry other) =>
      timestamp.compareTo(other.timestamp);

  @override
  late final int hashCode = state.hashCode ^ timestamp.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrismHistoryEntry &&
          state == other.state &&
          timestamp == other.timestamp;
}

/// Prism state observer implementation
final class PrismObserver$NavigatorImpl
    with ChangeNotifier
    implements PrismStateObserver {
  PrismObserver$NavigatorImpl(
    PrismNavigationState initialState, [
    List<PrismHistoryEntry>? history,
  ]) : _value = initialState,
       _history = history?.toSet().toList() ?? [] {
    // Add the initial state to the history.
    if (_history.isEmpty || _history.last.state != initialState) {
      _history.add(
        PrismHistoryEntry(state: initialState, timestamp: DateTime.now()),
      );
    }
    _history.sort();
  }

  PrismNavigationState _value;

  final List<PrismHistoryEntry> _history;

  @override
  List<PrismHistoryEntry> get history =>
      UnmodifiableListView<PrismHistoryEntry>(_history);

  @override
  void setHistory(Iterable<PrismHistoryEntry> history) {
    _history
      ..clear()
      ..addAll(history)
      ..sort();
  }

  @override
  PrismNavigationState get value => _value;

  bool changeState(
    PrismNavigationState Function(PrismNavigationState state) fn,
  ) {
    final prev = _value;
    final next = fn(prev);
    if (identical(next, prev)) return false;
    _value = next;

    late final historyEntry = PrismHistoryEntry(
      state: next,
      timestamp: DateTime.now(),
    );
    _history.add(historyEntry);
    if (_history.length > PrismStateObserver.maxHistoryLength)
      _history.removeAt(0);

    notifyListeners();
    return true;
  }
}
